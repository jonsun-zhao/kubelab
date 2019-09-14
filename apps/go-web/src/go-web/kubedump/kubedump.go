package kubedump

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/gorilla/mux"
)

var dir = "/data"

// GetObj ...
func GetObj(w http.ResponseWriter, r *http.Request) {

	params := mux.Vars(r)
	name := params["name"]

	// /data/node/_gke-rei-default-pool-d3692fcf-3svd.json
	raw, err := ioutil.ReadFile(filepath.Join(dir, name+".json"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		log.Print(err)
		return
	}

	var data map[string]interface{}
	_ = json.Unmarshal(raw, &data)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	json.NewEncoder(w).Encode(data)
}

// GetAll ...
func GetAll(w http.ResponseWriter, r *http.Request) {

	files, err := ioutil.ReadDir(dir)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		log.Print(err)
		return
	}

	for _, file := range files {
		n := strings.TrimSuffix(file.Name(), ".json")
		fmt.Fprintf(w, "<a href=\"/kubedump/"+n+"\">"+n+"</a><br/>")
	}
}
