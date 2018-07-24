package stress

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

// Run stress
func Run(w http.ResponseWriter, r *http.Request) {
	stressType := mux.Vars(r)["type"]

	switch stressType {
	case "cpu":

		var cpuload = 0.1
		var duration float64 = 10
		var cpucore int
		sampleInterval := 100 * time.Millisecond

		// use the specified cpuload
		loadValue := r.FormValue("load")
		if loadValue != "" {
			cpuload, _ = strconv.ParseFloat(loadValue, 64)
		}
		durationValue := r.FormValue("duration")
		if durationValue != "" {
			duration, _ = strconv.ParseFloat(durationValue, 64)
		}

		go stressCPU(sampleInterval, cpuload, duration, cpucore)

		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, `Type: %s
CpuLoad: %f (Target CPU load)
Duration: %f (Duration to run the stress in Seconds)
`, stressType, cpuload, duration)

	case "memory":
		size := int64(100)
		sizeValue := r.FormValue("size")
		if sizeValue != "" {
			size, _ = strconv.ParseInt(sizeValue, 0, 64)
		}

		go stressMemory(size)

		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "Type: %s\nMemory Size: %d(MB)\n", stressType, size)

	default:
		http.Error(w, "Unknown stress type",
			http.StatusInternalServerError)
		return
	}

}
