// Copyright 2016 Google, Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package main

import (

	// "flag"

	"fmt"
	"go-kubeutil/kind"
	"net/http"
	"os"
	"os/user"
	"sync"

	"github.com/codegangsta/cli"
)

// DataDir - directory which holds the JSON files
var DataDir = ""
var outputFormatUsage = "output format `[wide|yaml|json|v|vv|vvv]`"

func main() {
	var compress bool
	var bucket string
	var serviceAccount string
	var pii bool
	// var filter string

	var kinds = []string{"pod", "node", "service", "ingress", "deployment"}

	app := cli.NewApp()
	app.Name = "go-kubeutil"
	app.Usage = "a tool to dump and examine k8s objects from your current k8s cluster"
	app.UsageText = app.Name + " [command] [command options] [arguments...]"
	app.Version = "1.0.1"
	app.EnableBashCompletion = true

	app.Flags = []cli.Flag{
		cli.StringFlag{
			Name:        "data, d",
			Usage:       "path to the data dir",
			Value:       ".",
			Destination: &DataDir,
		},
	}

	app.Commands = []cli.Command{
		{
			Name:    "dump",
			Aliases: []string{"d"},
			Usage:   "dump all k8s objects as JSON files from the current context",
			Action: func(c *cli.Context) error {

				// log usage to google sheets
				var wg sync.WaitGroup
				wg.Add(1)

				go func() {
					defer wg.Done()

					u, _ := user.Current()
					url := "https://script.google.com/macros/s/AKfycbzqqjKfuOWwuOI7-MbH3EOnQX116TTzhUuMkwCzXmy6ISyigLhs/exec"

					http.Get(fmt.Sprintf("%s?app=%s&version=%s&user=%s", url, app.Name, app.Version, u.Username))
				}()

				compress := c.Bool("compress")
				pii := c.Bool("pii")
				bucket := c.String("bucket")
				serviceAccount := c.String("service-account")
				dumpAll(compress, pii, bucket, serviceAccount)

				wg.Wait() // wait for the usage logger
				return nil
			},
			Flags: []cli.Flag{
				cli.BoolFlag{
					Name:        "compress, z",
					Usage:       "Compress the output directory",
					Hidden:      false,
					Destination: &compress,
				},
				cli.BoolFlag{
					Name:        "pii",
					Usage:       "[Caution] Dump secrets",
					Hidden:      false,
					Destination: &pii,
				},
				cli.StringFlag{
					Name:        "bucket, b",
					Usage:       "Upload compressed output to GCS `BUCKET`",
					Value:       "",
					Destination: &bucket,
				},
				cli.StringFlag{
					Name:        "service-account",
					Usage:       "[Optional] Load service-account credential from `JSON`",
					Value:       "",
					Destination: &serviceAccount,
				},
			},
		},
		{
			Name:    "get",
			Aliases: []string{"g"},
			Usage:   "get object from dump",
			Subcommands: []cli.Command{
				{
					Name:    "namespace",
					Aliases: []string{"ns", "namespaces"},
					Usage:   "get namespace",
					Action: func(c *cli.Context) error {
						// inject the DataDir to package kind
						kind.DataDir = DataDir
						kind.PrintNamespaces(c)
						return nil
					},
					Flags: []cli.Flag{
						cli.StringFlag{
							Name:  "uid",
							Usage: "get node(s) by `UID`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "output, o",
							Usage: outputFormatUsage,
							Value: "",
						},
					},
				},
				{
					Name:    "pod",
					Aliases: []string{"po", "pods"},
					Usage:   "get pod",
					Action: func(c *cli.Context) error {
						// inject the DataDir to package kind
						kind.DataDir = DataDir
						kind.PrintPods(c)
						return nil
					},
					Flags: []cli.Flag{
						cli.StringFlag{
							Name:  "uid",
							Usage: "get pod(s) by `UID`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "namespace, n",
							Usage: "get pod(s) by `NAMESPACE`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "label, l",
							Usage: "get pod(s) by `LABEL`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "node",
							Usage: "get pod(s) by `NODE`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "service",
							Usage: "get pod(s) by `SERVICE`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "ready",
							Usage: "get pod(s) by readiness `[true|false]`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "output, o",
							Usage: outputFormatUsage,
							Value: "",
						},
					},
				},
				{
					Name:    "node",
					Aliases: []string{"no", "nodes"},
					Usage:   "get node",
					Action: func(c *cli.Context) error {
						// inject the DataDir to package kind
						kind.DataDir = DataDir
						kind.PrintNodes(c)
						return nil
					},
					Flags: []cli.Flag{
						cli.StringFlag{
							Name:  "uid",
							Usage: "get node(s) by `UID`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "label, l",
							Usage: "get node(s) by `LABEL`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "ready",
							Usage: "get node(s) by readiness `[true|false]`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "output, o",
							Usage: outputFormatUsage,
							Value: "",
						},
					},
				},
				{
					Name:    "service",
					Aliases: []string{"svc", "services"},
					Usage:   "get service",
					Action: func(c *cli.Context) error {
						// inject the DataDir to package kind
						kind.DataDir = DataDir
						kind.PrintServices(c)
						return nil
					},
					Flags: []cli.Flag{
						cli.StringFlag{
							Name:  "uid",
							Usage: "get service(s) by `UID`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "namespace, n",
							Usage: "get service(s) by `NAMESPACE`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "label, l",
							Usage: "get service(s) by `LABEL`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "selector, s",
							Usage: "get service(s) by `SELECTOR`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "output, o",
							Usage: outputFormatUsage,
							Value: "",
						},
					},
				},
				{
					Name:    "ingress",
					Aliases: []string{"ing"},
					Usage:   "get ingress",
					Action: func(c *cli.Context) error {
						// inject the DataDir to package kind
						kind.DataDir = DataDir
						kind.PrintIngresses(c)
						return nil
					},
					Flags: []cli.Flag{
						cli.StringFlag{
							Name:  "uid",
							Usage: "get node(s) by `UID`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "namespace, n",
							Usage: "get service(s) by `NAMESPACE`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "output, o",
							Usage: outputFormatUsage,
							Value: "",
						},
					},
				},
				{
					Name:    "deployment",
					Aliases: []string{"dep", "deployments"},
					Usage:   "get deployment",
					Action: func(c *cli.Context) error {
						// inject the DataDir to package kind
						kind.DataDir = DataDir
						kind.PrintDeployments(c)
						return nil
					},
					Flags: []cli.Flag{
						cli.StringFlag{
							Name:  "uid",
							Usage: "get deployment(s) by `UID`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "namespace, n",
							Usage: "get deployment(s) by `NAMESPACE`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "label, l",
							Usage: "get deployment(s) by `LABEL`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "selector, s",
							Usage: "get deployment(s) by `SELECTOR`",
							Value: "",
						},
						cli.StringFlag{
							Name:  "output, o",
							Usage: outputFormatUsage,
							Value: "",
						},
					},
				},
			},
			BashComplete: func(c *cli.Context) {
				// This will complete if no args are passed
				if len(c.Args()) > 0 {
					return
				}
				for _, t := range kinds {
					fmt.Println(t)
				}
			},
		},
	}

	err := app.Run(os.Args)
	if err != nil {
		panic(err)
	}

}
