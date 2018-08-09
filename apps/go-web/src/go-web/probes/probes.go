package probes

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

func Liveness(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Liveness probe hit")
}

func Readiness(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Readiness probe hit")
}

func Health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "ok")
}

func Ping(w http.ResponseWriter, r *http.Request, beUrl *string) {
	if *beUrl == "" {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "Backend not specified")
		return
	}

	response, err := http.Get("http://" + *beUrl)
	if err != nil {
		log.Printf("The HTTP request failed with error %s\n", err)
	}
	defer response.Body.Close()

	if response.StatusCode >= 500 {
		http.Error(w, err.Error(), http.StatusBadRequest)
	}

	data, _ := ioutil.ReadAll(response.Body)
	fmt.Fprintf(w, string(data))
}
