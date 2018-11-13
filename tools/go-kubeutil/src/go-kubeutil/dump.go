package main

import (
	"encoding/json"
	"fmt"
	"go-kubeutil/utils"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// dump k8s objects by kind ("pod", "service" etc)
func dumpObject(kind, outPath string) {
	args := fmt.Sprintf("get %s --all-namespaces -o json", kind)
	outs := utils.RunCmd("kubectl", args)
	if len(outs) <= 0 {
		return
	}

	var data map[string]interface{}
	err := json.Unmarshal(outs, &data)
	if err != nil {
		panic(err)
	}

	for _, v := range data["items"].([]interface{}) {
		o := utils.ToMap(v)
		metadata := utils.ToMap(o["metadata"])

		name := metadata["name"].(string)
		namespace := metadata["namespace"].(string)

		dir := filepath.Join(outPath, kind)
		// if t == "pod" {
		// 	// group pods by node
		// 	dir = dir + "/" + toMap(o["spec"])["nodeName"].(string)
		// }

		if _, err := os.Stat(dir); os.IsNotExist(err) {
			os.MkdirAll(dir, os.ModePerm)
		}

		jsonFile := fmt.Sprintf("%s/%s_%s.json", dir, namespace, name)
		jsonData, _ := json.MarshalIndent(o, "", "\t")

		utils.DumpJSON(jsonFile, jsonData)
	}
}

func dumpAll(compress, pii bool, bucket, serviceAccount string) {
	currentTime := time.Now()
	fmt.Println("Current time is:", currentTime.Format(time.RFC850))

	// fetch current-context
	outs := utils.RunCmd("kubectl", "config current-context")
	if len(outs) <= 0 {
		fmt.Println("!! Failed to retrieve current-context")
		return
	}
	currentContext := strings.TrimSpace(string(outs))
	fmt.Println("==> Current context: ", currentContext)

	// prepare output paths
	outPath := currentContext + "_" + currentTime.Format("20060102150405")
	gzPath := outPath + ".tar.gz"

	kubeTypes := []string{
		"node",
		"pod",
		"horizontalpodautoscaler",
		"service",
		"endpoints",
		"ingress",
		"deployment",
		"replicaset",
		"replicationcontroller",
		"statefulset",
		"storageclass",
		"persistentvolume",
		"persistentvolumeclaim",
		"job",
		"cronjob",
		"serviceaccount",
		"role",
		"rolebinding",
		"clusterrole",
		"clusterrolebinding",
		"networkpolicy",
		"podsecuritypolicy",
		"configmap",
		"event",
		"namespace",
	}

	if pii {
		kubeTypes = append(kubeTypes, "secret")
	}

	for _, v := range kubeTypes {
		dumpObject(v, outPath)
	}

	if compress {
		utils.RunCmd("tar", fmt.Sprintf("-zcf %s %s", gzPath, outPath))
	}

	if bucket != "" {
		if !compress {
			utils.RunCmd("tar", fmt.Sprintf("-zcf %s %s", gzPath, outPath))
		}
		utils.UploadToGcsBucket(bucket, gzPath, serviceAccount)
		// utils.RunCmd("gsutil", fmt.Sprintf("cp %s gs://%s/%[1]s", gzPath, *bucketNamePtr))
	}

	fmt.Printf("==> done. data saved in dir: %s\n", outPath)
}
