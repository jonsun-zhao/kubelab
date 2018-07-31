package main

import (
	"fmt"
	"go-web/dns"
	"go-web/kubedump"
	"go-web/person"
	"go-web/probes"
	"go-web/stress"
	"log"
	"net/http"
	"os"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	mgo "gopkg.in/mgo.v2"
)

// Index ...
func Index(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	host, _ := os.Hostname()
	fmt.Fprintf(w, "Hello, world!\n")
	fmt.Fprintf(w, "Version: 1.0.0\n")
	fmt.Fprintf(w, "Hostname: %s\n", host)
}

// NotFound 404 handler
func NotFound(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusNotFound)
	w.Write([]byte("404 - page not found...\n"))
}

// Error sample error
func Error(w http.ResponseWriter, r *http.Request) {
	http.Error(w, "500 - a horrible error emerged...\n",
		http.StatusInternalServerError)
}

// logging middleware
func loggingMiddleware(next http.Handler) http.Handler {
	return handlers.CombinedLoggingHandler(os.Stdout, next)
}

// Run both http and https
func Run(router *mux.Router, addr string, sslAddr string, sslCert string, sslKey string) chan error {
	errs := make(chan error)

	// Starting HTTP server
	go func() {
		log.Printf("Staring HTTP service on %s ...", addr)

		if err := http.ListenAndServe(addr, router); err != nil {
			errs <- err
		}

	}()

	// Starting HTTPS server
	go func() {
		log.Printf("Staring HTTPS service on %s ...", sslAddr)
		if err := http.ListenAndServeTLS(sslAddr, sslCert, sslKey, router); err != nil {
			errs <- err
		}
	}()

	return errs
}

// main function to boot up everything
func main() {
	port := "8000"
	if fromEnv := os.Getenv("PORT"); fromEnv != "" {
		port = fromEnv
	}

	sslPort := "10443"
	if fromEnv := os.Getenv("SSL_PORT"); fromEnv != "" {
		sslPort = fromEnv
	}

	mongoDbURL := os.Getenv("MONGODB_URL")

	router := mux.NewRouter()
	router.NotFoundHandler = loggingMiddleware(http.HandlerFunc(NotFound))
	router.Use(loggingMiddleware)
	router.HandleFunc("/", Index)
	router.HandleFunc("/error", Error).Methods("GET")

	// person
	if mongoDbURL != "" {
		session, err := mgo.Dial(mongoDbURL)
		if err != nil {
			panic(err)
		}
		defer session.Close()
		person.Init(session)

	} else {
		person.Init(nil)
	}
	router.HandleFunc("/people", person.GetAll).Methods("GET")
	router.HandleFunc("/people/{id:[0-9]+}", person.Get).Methods("GET")
	router.HandleFunc("/people/{id:[0-9]+}", person.Create).Methods("POST")
	router.HandleFunc("/people/{id:[0-9]+}", person.Update).Methods("PUT")
	router.HandleFunc("/people/{id:[0-9]+}", person.Delete).Methods("DELETE")

	// stress
	router.HandleFunc("/stress/{type}", stress.Run).Methods("GET")

	// dns
	router.HandleFunc("/dns", dns.Run).Methods("GET")

	// probes
	router.HandleFunc("/health", probes.Health).Methods("GET")
	router.HandleFunc("/liveness", probes.Liveness).Methods("GET")
	router.HandleFunc("/readiness", probes.Readiness).Methods("GET")

	// kubedump
	router.HandleFunc("/kubedump/", kubedump.GetAll).Methods("GET")
	router.HandleFunc("/kubedump/{kind}", kubedump.GetObjs).Methods("GET")
	router.HandleFunc("/kubedump/{kind}/{name}", kubedump.GetObj).Methods("GET")

	// log.Fatal(http.ListenAndServe(":"+port, router))
	errs := Run(router, ":"+port, ":"+sslPort, "server.crt", "server.key")

	// This will run forever until channel receives error
	select {
	case err := <-errs:
		log.Printf("Could not start serving service due to (error: %s)", err)
	}
}
