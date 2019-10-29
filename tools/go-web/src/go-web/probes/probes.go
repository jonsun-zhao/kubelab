package probes

import (
	"fmt"
	g "go-web/grpc"
	"io/ioutil"
	"log"
	"net/http"

	"contrib.go.opencensus.io/exporter/stackdriver/propagation"
	"go.opencensus.io/plugin/ochttp"
)

// Liveness probe
func Liveness(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Liveness probe hit\n")
}

// Readiness probe
func Readiness(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Readiness probe hit\n")
}

// Health probe
func Health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "ok\n")
}

// PingBackend - probe backend service
func PingBackend(w http.ResponseWriter, r *http.Request, beURL string) {
	if beURL == "" {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "Backend not specified\n")
		return
	}

	url := "http://" + beURL
	fmt.Fprintf(w, "Reaching backend: %s\n\n", url)

	c := &http.Client{
		Transport: &ochttp.Transport{
			// Use Google Cloud propagation format.
			Propagation: &propagation.HTTPFormat{},
		},
	}
	req, err := http.NewRequest("GET", url, nil)

	// propagate trace id to outgoing event
	req = req.WithContext(r.Context())

	// fetch header foo from the frontend request
	foo := r.Header.Get("foo")
	if foo != "" {
		// pass on the header to the backend
		req.Header.Add("foo", foo)
	}

	// temp test
	// req.Header.Add("X-APP-API_SIGNATURE", "SsxfLRHirn+GwGbuJieoqPFfRgnSF0ebJ2sXqZCyQ2w=;")
	// req.Header.Add("X-APP-API_TIMESTAMP", "1563425167;")

	resp, err := c.Do(req)
	if err != nil {
		log.Printf("The HTTP request failed with error %s\n", err)
		fmt.Fprintf(w, "== Error ==\n%s\n", err.Error())
		return
	}
	// this call will panic if the previous error handing block did not return
	defer resp.Body.Close()

	data, _ := ioutil.ReadAll(resp.Body)
	fmt.Fprintf(w, "== Result ==\n")
	fmt.Fprintf(w, "%s\n", string(data))
}

// PingGRPCBackend - probe grpc backend service
func PingGRPCBackend(w http.ResponseWriter, r *http.Request, grpcBeAddr string, cert string) {
	if grpcBeAddr == "" {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "gRPC Backend not specified\n")
		return
	}

	results := *g.PingBackend(r.Context(), grpcBeAddr, cert)

	for _, l := range results {
		fmt.Fprintf(w, l+"\n")
	}
}
