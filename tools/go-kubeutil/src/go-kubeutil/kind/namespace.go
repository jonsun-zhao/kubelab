package kind

import (
	"fmt"
	"go-kubeutil/utils"
	"time"

	"github.com/codegangsta/cli"
)

// Namespaces holds the created namespace objects
var Namespaces []*Namespace

// Namespace struct
type Namespace struct {
	Name              string
	UID               string
	SelfLink          string
	Annotations       []*Annotation
	Status            string
	CreationTimestamp time.Time
	FilePath          string
}

// GetNamespace get namespace by name
func GetNamespace(name string) *Namespace {
	for _, v := range GetNamespaces() {
		if v.Name == name {
			return v
		}
	}
	return nil
}

// GetNamespaces create namespace objects from files
func GetNamespaces() []*Namespace {
	if len(Namespaces) > 0 {
		return Namespaces
	}
	for _, v := range GetKinds(GetNamespaceByFile, "namespace") {
		Namespaces = append(Namespaces, v.(*Namespace))
	}
	return Namespaces
}

// GetNamespaceByFile create namespace object from file
func GetNamespaceByFile(file string) Kind {
	k := new(Namespace)

	data := utils.ReadFileToMap(file)

	o := utils.ToMap(data)
	metadata := utils.ToMap(o["metadata"])
	// spec := utils.ToMap(o["spec"])
	status := utils.ToMap(o["status"])

	k.Name = metadata["name"].(string)
	k.UID = metadata["uid"].(string)
	k.CreationTimestamp = utils.ToTime(metadata["creationTimestamp"].(string))
	k.Status = status["phase"].(string)

	k.SelfLink = metadata["selfLink"].(string)
	k.Annotations = GetAnnotations(metadata["annotations"])

	k.FilePath = file
	return k
}

// FilterNamespaces filter namespace by flags
func FilterNamespaces(c *cli.Context) []Kind {
	args := c.Args()
	uid := c.String("uid")

	var candidates []Kind
	var found []Kind

	// check args which should contains pod names
	for _, v := range GetNamespaces() {
		if c.NArg() > 0 {
			for _, a := range args {
				if utils.Match(v.Name, a, true) {
					candidates = append(candidates, v)
				}
			}
		} else {
			candidates = append(candidates, v)
		}
	}

	for _, v := range candidates {
		o := v.(*Namespace)
		// check uid
		if uid != "" && !utils.Match(o.UID, uid, true) {
			continue
		}
		// found it if it reachs this point
		found = append(found, o)
	}

	return found
}

// PrintNamespaces print namespaces
func PrintNamespaces(c *cli.Context) {
	PrintKinds(c, FilterNamespaces, NamespaceHeaders)
}

// GetName implements kind.GetName()
func (k *Namespace) GetName() string {
	return k.Name
}

// PrintV implements kind.PrintV()
func (k *Namespace) PrintV(verbosity string) {
	// print Namespaces
	fmt.Printf("# NAMESPACE\n")
	switch verbosity {
	case "v", "vv":
		utils.PrintStructInYAML(k)
	case "vvv":
		PrintRaw(k)
	}
}

// NamespaceHeaders construct namespace header
func NamespaceHeaders(wide bool) string {
	headers := "Name | UID | Status | Age"
	if wide {
		headers += " | CreationTimestamp"
	}
	return headers
}

// ToStr implements kind.ToStr()
func (k *Namespace) ToStr(wide bool) string {
	str := fmt.Sprintf("%s | %s | %s | %s",
		k.Name,
		k.UID,
		k.Status,
		utils.Age(k.CreationTimestamp),
	)
	if wide {
		str += fmt.Sprintf(" | %s", utils.Time(k.CreationTimestamp))
	}
	return str
}

// GetFilePath implements kind.GetFilePath()
func (k *Namespace) GetFilePath() string {
	return k.FilePath
}
