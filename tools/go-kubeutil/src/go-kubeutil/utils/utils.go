package utils

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/codegangsta/cli"

	"cloud.google.com/go/storage"
	"golang.org/x/net/context"
	"google.golang.org/api/option"
	yaml "gopkg.in/yaml.v2"
)

func PrintCommand(cmd *exec.Cmd) {
	fmt.Printf("==> Executing: %s\n", strings.Join(cmd.Args, " "))
}

func PrintError(err error) {
	if err != nil {
		os.Stderr.WriteString(fmt.Sprintf("==> Error: %s\n", err.Error()))
	}
}

func PrintOutput(outs []byte) {
	if len(outs) > 0 {
		fmt.Printf("==> Output: %s\n", string(outs))
	}
}

func DumpJSON(fileName string, jsonData []byte) {
	// write to JSON file
	jsonFile, err := os.Create(fileName)

	if err != nil {
		panic(err)
	}
	defer jsonFile.Close()

	jsonFile.Write(jsonData)
	jsonFile.Close()

	fmt.Println("==> JSON data written to", jsonFile.Name())
}

func ToMap(i interface{}) map[string]interface{} {
	return i.(map[string]interface{})
}

func RunCmd(command string, arg string) []byte {
	args := strings.Split(arg, " ")
	cmd := exec.Command(command, args...)

	// Stdout buffer
	cmdOutput := &bytes.Buffer{}
	// Attach buffer to command
	cmd.Stdout = cmdOutput

	// Execute command
	PrintCommand(cmd)
	err := cmd.Run() // will wait for command to return
	PrintError(err)
	// Only output the commands stdout
	// printOutput(cmdOutput.Bytes())
	return cmdOutput.Bytes()
}

// write gz to gcs bucket
func UploadToGcsBucket(bucketName, fileName, saJSONPath string) {
	ctx := context.Background()

	var client *storage.Client
	var err error

	if saJSONPath != "" {
		client, err = storage.NewClient(ctx, option.WithCredentialsFile(saJSONPath))
	} else {
		// [default]
		// use service account key from JSON specified in
		// env GOOGLE_APPLICATION_CREDENTIALS
		client, err = storage.NewClient(ctx)
	}

	if err != nil {
		panic(err)
	}

	wc := client.Bucket(bucketName).Object(fileName).NewWriter(ctx)
	wc.ContentType = "application/x-tar"
	// wc.ACL = []storage.ACLRule{{storage.AllUsers, storage.RoleReader}}

	// read gz into bytes
	content, err := ioutil.ReadFile(fileName)
	if err != nil {
		panic(err)
	}

	if _, err := wc.Write(content); err != nil {
		// TODO: handle error.
		// Note that Write may return nil in some error situations,
		// so always check the error from Close.
		panic(err)
	}

	if err := wc.Close(); err != nil {
		// TODO: handle error.
		panic(err)
	}
	fmt.Printf("==> [%s] is uploaded to bucket [%s]\n", fileName, bucketName)
}

func InterfaceSlice(slicePtr interface{}) []interface{} {
	s := reflect.Indirect(reflect.ValueOf(slicePtr))
	if s.Kind() != reflect.Slice {
		panic("InterfaceSlice() given a non-slice type")
	}

	ret := make([]interface{}, s.Len())

	for i := 0; i < s.Len(); i++ {
		ret[i] = s.Index(i).Interface()
	}

	return ret
}

func GetPath(dataDir, kind, name string) string {
	dir := filepath.Join(dataDir, kind)

	files, err := ioutil.ReadDir(dir)
	if err != nil {
		log.Print(err)
		return ""
	}

	var found = ""
	for _, f := range files {
		if matched, _ := regexp.MatchString(".*"+name+".*", f.Name()); matched {
			found = filepath.Join(dir, f.Name())
		}
	}

	return found
}

func PrintStructInJSON(intPtr interface{}) {
	jsonData, _ := json.MarshalIndent(intPtr, "", "\t")
	fmt.Println(string(jsonData))
}

func PrintStructInYAML(intPtr interface{}) {
	// print the obj individually if the intPtr is a pointer to a Slice
	if reflect.Indirect(reflect.ValueOf(intPtr)).Kind() == reflect.Slice {
		for _, v := range InterfaceSlice(intPtr) {
			yamlData, _ := yaml.Marshal(v)
			fmt.Printf("---\n%s\n", string(yamlData))
		}
	} else {
		yamlData, _ := yaml.Marshal(intPtr)
		fmt.Printf("---\n%s\n", string(yamlData))
	}
}

func ToTime(i interface{}) time.Time {
	layout := "2006-01-02T15:04:05Z"
	t, err := time.Parse(layout, i.(string))
	if err != nil {
		log.Fatal(err)
	}
	return t
}

func ReadFile(file string) []byte {
	// check if the json file exists
	raw, err := ioutil.ReadFile(file)
	if err != nil {
		log.Fatal(err)
	}
	return raw
}

func ReadFileToMap(file string) map[string]interface{} {
	// read the json file into data
	var data map[string]interface{}
	json.Unmarshal(ReadFile(file), &data)

	return data
}

func Match(target, source string, fuss bool) bool {
	if fuss {
		matched, _ := regexp.MatchString(target, source)
		return matched
	}
	return target == source
}

func FloatToString(f float64) string {
	// to convert a float number to a string
	return strconv.FormatFloat(f, 'f', 0, 64)
}

func Index(vs []string, t string) int {
	for i, v := range vs {
		if v == t {
			return i
		}
	}
	return -1
}

func Include(vs []string, t string) bool {
	return Index(vs, t) >= 0
}

func Wide(c *cli.Context) bool {
	switch c.String("output") {
	case "w":
		fallthrough
	case "wide":
		return true
	}
	return false
}

func Age(t time.Time) string {
	hours := time.Since(t).Hours()
	days := hours / 24
	if days < 1 {
		return fmt.Sprintf("%.0fh", hours)
	}
	return fmt.Sprintf("%.0fd", days)
}

func Time(t time.Time) string {
	return t.Format(time.RFC3339)
}

// func GetProjectNumber() {
// 	ctx := context.Background()
// 	client, err := google.DefaultClient(ctx, compute.ComputeScope)
// 	if err != nil {
// 		fmt.Println(err)
// 	}
// 	computeService, err := compute.New(client)
// 	projectGetCall := computeService.Projects.Get("<project_id>")
// 	project, err := projectGetCall.Do()
// 	fmt.Println(project)
// }

// type QuerySlice struct {
// 	Operator string
// 	Queries  []*Query
// }

// type Query struct {
// 	Key      string
// 	Value    string
// 	Operator string
// }

// var OperatorOr = " OR "
// var OperatorAnd = " AND "

// func parseFilter(s string) *QuerySlice {
// 	qs := new(QuerySlice)
// 	var q []*Query

// 	orFound := strings.Contains(s, OperatorOr)
// 	andFound := strings.Contains(s, OperatorAnd)

// 	if orFound && andFound {
// 		log.Fatal("Either `OR` or `AND`, not both please.")
// 	}

// 	if orFound {
// 		qs.Operator = "OR"
// 		for _, v := range strings.Split(s, OperatorOr) {
// 			q = append(q, parseQuery(v))
// 			qs.Queries = q
// 		}
// 	}

// 	if andFound {
// 		qs.Operator = "AND"
// 		for _, v := range strings.Split(s, OperatorAnd) {
// 			q = append(q, parseQuery(v))
// 			qs.Queries = q
// 		}
// 	}

// 	if !orFound && !andFound {
// 		q = append(q, parseQuery(s))
// 		qs.Queries = q
// 	}

// 	return qs
// }

// func parseQuery(s string) *Query {
// 	var acceptedOperators = []string{
// 		"==",
// 		"~=",
// 		"!=",
// 	}

// 	for _, o := range acceptedOperators {
// 		if strings.Contains(s, o) {
// 			segments := strings.Split(s, o)
// 			return &Query{
// 				segments[0], // key
// 				segments[1], // value
// 				o,           // operator
// 			}
// 		}
// 	}

// 	return nil
// }

// func fieldValue(i interface{}, field string) *reflect.Value {
// 	if strings.Contains(field, ".") {
// 		segments := strings.SplitN(field, ".", 2)

// 		r := reflect.ValueOf(i)
// 		f := reflect.Indirect(r).FieldByName(segments[0])

// 		return fieldValue(f.Interface(), segments[1])
// 	}

// 	r := reflect.ValueOf(i)
// 	// fmt.Printf("r: %v\n", r)
// 	f := reflect.Indirect(r).FieldByName(field)
// 	// fmt.Printf("f: %v\n", f)
// 	return &f
// }
