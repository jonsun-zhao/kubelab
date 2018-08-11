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

	url := "http://" + *beUrl
	fmt.Fprintf(w, "Reaching backend: %s\n\n", url)

	c := &http.Client{}
	req, err := http.NewRequest("GET", url, nil)
	foo := r.Header.Get("foo")
	if foo != "" {
		req.Header.Add("foo", foo)
	}

	resp, err := c.Do(req)
	if err != nil {
		log.Printf("The HTTP request failed with error %s\n", err)
		fmt.Fprintf(w, "== Error ==\n%s\n", err.Error())
		return
	}
	defer resp.Body.Close()

	data, _ := ioutil.ReadAll(resp.Body)
	fmt.Fprintf(w, "== Result ==\n")
	fmt.Fprintf(w, "%s\n", string(data))
}
