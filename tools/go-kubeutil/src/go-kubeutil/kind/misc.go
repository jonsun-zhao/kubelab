package kind

import (
	"fmt"
	"go-kubeutil/utils"
	"io/ioutil"
	"log"
	"path/filepath"
	"sort"
	"strings"
	"sync"

	"github.com/codegangsta/cli"

	"github.com/ryanuber/columnize"
)

// DataDir holds the path to the dump dir
var DataDir string

// Kind interface
type Kind interface {
	ToStr(bool) string
	GetFilePath() string
	PrintV(string)
	GetName() string
}

// HeaderFunc function which construct the header string
type HeaderFunc func(bool) string

// PrintTabular print kind object in tabular form
func PrintTabular(fn HeaderFunc, k []Kind, wide bool) {
	output := []string{fn(wide)}
	for _, v := range k {
		output = append(output, v.ToStr(wide))
	}
	result := columnize.SimpleFormat(output)
	fmt.Printf("%s\n\n", result)
}

// PrintRaw print raw JSON files
func PrintRaw(k Kind) {
	content := string(utils.ReadFile(k.GetFilePath()))
	fmt.Println(content)
}

// FilterFunc function which filter objects by flags
type FilterFunc func(c *cli.Context) []Kind

// PrintKinds print kind objects
func PrintKinds(c *cli.Context, fnF FilterFunc, fnH HeaderFunc) {
	format := c.String("output")

	objs := fnF(c)

	switch format {
	case "", "w", "wide":
		PrintTabular(fnH, objs, utils.Wide(c))
	case "yaml":
		utils.PrintStructInYAML(objs)
	case "json":
		utils.PrintStructInJSON(objs)
	case "v", "vv", "vvv":
		for _, s := range objs {
			s.PrintV(format)
		}
	default:
		fmt.Printf("Output format: [%s] is not supported.\n", format)
	}

	fmt.Printf("* %d found\n", len(objs))
}

// GetKindsByFileFunc function which create kind object from file
type GetKindsByFileFunc func(string) Kind

// GetKinds create kind objects from files
func GetKinds(fnG GetKindsByFileFunc, kind string) []Kind {
	var kinds []Kind

	dir := filepath.Join(DataDir, kind)

	files, err := ioutil.ReadDir(dir)
	if err != nil {
		log.Fatal(err)
	}

	kindsChan := make(chan Kind, len(files))
	var wg sync.WaitGroup

	for _, f := range files {
		wg.Add(1)
		go func(path string) {
			defer wg.Done()
			kindsChan <- fnG(path)
		}(filepath.Join(dir, f.Name()))
	}

	wg.Wait()
	close(kindsChan)

	for v := range kindsChan {
		kinds = append(kinds, v)
	}

	sort.Slice(kinds, func(i, j int) bool { return kinds[i].GetName() < kinds[j].GetName() })

	return kinds
}

// Label struct
type Label struct {
	Key   string
	Value string
}

// GetLabels create labels
func GetLabels(i interface{}) []*Label {
	var labels []*Label

	if i == nil {
		return nil
	}

	for k, v := range utils.ToMap(i) {
		labels = append(labels, &Label{k, v.(string)})
	}
	return labels
}

// LabelContains check if labels l contains labels s
func LabelContains(l []*Label, s []*Label) bool {
	var labelStrs []string
	var selectorStrs []string

	// short circuit if selector is empty
	if len(s) == 0 {
		return false
	}

	for _, v := range l {
		labelStrs = append(labelStrs, v.ToStr())
	}

	for _, v := range s {
		selectorStrs = append(selectorStrs, v.ToStr())
	}

	for _, v := range selectorStrs {
		if !utils.Include(labelStrs, v) {
			// break early when a selector does not match any label
			return false
		}
	}
	return true
}

// Match labelStr format: key=value
func (l *Label) Match(labelStr string) bool {
	pair := strings.Split(labelStr, "=")
	// fmt.Printf("Label - pair: %v\n", pair)
	// fmt.Printf("Label - l: %v\n", l)

	if l.Key == pair[0] && l.Value == pair[1] {
		return true
	}
	return false
}

// ToStr return label as string
func (l *Label) ToStr() string {
	return l.Key + "=" + l.Value
}

// Annotation struct
type Annotation struct {
	Key   string
	Value string
}

// GetAnnotations create annotations
func GetAnnotations(i interface{}) []*Annotation {
	var annotations []*Annotation

	if i == nil {
		return nil
	}

	for k, v := range utils.ToMap(i) {
		annotations = append(annotations, &Annotation{k, v.(string)})
	}
	return annotations
}

// ToStr return annotation as string
func (a *Annotation) ToStr() string {
	return a.Key + "=" + a.Value
}
