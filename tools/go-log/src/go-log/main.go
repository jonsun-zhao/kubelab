/*
glog-example
------------

background
---
You probably want to read the source code comments at the top of the glog.go file in
the golang/glog repository on github.com. Located here: https://github.com/golang/glog/blob/master/glog.go

setup
---

	$ go get github.com/golang/glog
	$ mkdir log

run
---

	$ go run example.go -stderrthreshold=FATAL -log_dir=./log
or

	$ go run example.go -stderrthreshold=FATAL -log_dir=./log -v=2
or

	$ go run example.go -logtostderr=true
or

	$ go run example.go -logtostderr=true -v=2

*/

package main

import (
	"flag"
	"fmt"
	"os"
	"strconv"

	"github.com/golang/glog"
)

func usage() {
	fmt.Fprintf(os.Stderr, "usage: example -stderrthreshold=[INFO|WARN|FATAL] -log_dir=[string]\n")
	flag.PrintDefaults()
	os.Exit(2)
}

func init() {
	flag.Usage = usage
	// NOTE: This next line is key you have to call flag.Parse() for the command line
	// options for "flags" that are defined in the glog module to be picked up.
	flag.Parse()
}

func main() {
	count := 100
	if fromEnv := os.Getenv("COUNT"); fromEnv != "" {
		count, _ = strconv.Atoi(fromEnv)
	}

	for i := 0; i < count; i++ {
		glog.V(2).Infof("LINE: %d", i)
		message := fmt.Sprintf("TEST LINE: %d", i)
		glog.Error(message)
	}
	glog.Flush()
}
