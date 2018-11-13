package kind

import (
	"fmt"
	"go-kubeutil/utils"
	"strings"
	"time"

	"github.com/codegangsta/cli"
)

// Deployments holds the created deployment objects
var Deployments []*Deployment

// Deployment struct
type Deployment struct {
	Name              string
	UID               string
	Namespace         string
	SelfLink          string
	Labels            []*Label
	Annotations       []*Annotation
	Selectors         []*Label
	Conditions        []*DeploymentCondition
	Replicas          string
	AvailableReplicas string
	ReadyReplicas     string
	UpdatedReplicas   string
	CreationTimestamp time.Time
	FilePath          string
}

// GetDeployment get deployment by name and namespace
func GetDeployment(name, namespace string) *Deployment {
	for _, v := range GetDeployments() {
		if v.Name == name && v.Namespace == namespace {
			return v
		}
	}
	return nil
}

// GetDeployments create deployments from files
func GetDeployments() []*Deployment {
	if len(Deployments) > 0 {
		return Deployments
	}
	for _, v := range GetKinds(GetDeploymentByFile, "deployment") {
		Deployments = append(Deployments, v.(*Deployment))
	}
	return Deployments
}

// GetDeploymentByFile create deployment from file
func GetDeploymentByFile(file string) Kind {
	k := new(Deployment)

	data := utils.ReadFileToMap(file)

	o := utils.ToMap(data)
	metadata := utils.ToMap(o["metadata"])
	spec := utils.ToMap(o["spec"])
	status := utils.ToMap(o["status"])

	k.Name = metadata["name"].(string)
	k.UID = metadata["uid"].(string)
	k.Namespace = metadata["namespace"].(string)
	k.CreationTimestamp = utils.ToTime(metadata["creationTimestamp"].(string))

	k.SelfLink = metadata["selfLink"].(string)
	k.Labels = GetLabels(metadata["labels"])
	k.Annotations = GetAnnotations(metadata["annotations"])

	if v, ok := spec["selector"]; ok {
		if matchLabels, ok := utils.ToMap(v)["matchLabels"]; ok {
			k.Selectors = GetLabels(matchLabels)
		}
	}

	if v, ok := spec["replicas"]; ok {
		k.Replicas = utils.FloatToString(v.(float64))
	}
	if v, ok := status["availableReplicas"]; ok {
		k.AvailableReplicas = utils.FloatToString(v.(float64))
	}
	if v, ok := status["readyReplicas"]; ok {
		k.ReadyReplicas = utils.FloatToString(v.(float64))
	}
	if v, ok := status["updatedReplicas"]; ok {
		k.UpdatedReplicas = utils.FloatToString(v.(float64))
	}

	k.Conditions = GetDeploymentConditions(status["conditions"].([]interface{}))

	k.FilePath = file
	return k
}

// FilterDeployments filter deployment by flags
func FilterDeployments(c *cli.Context) []Kind {
	args := c.Args()
	uid := c.String("uid")
	label := c.String("label")
	namespace := c.String("namespace")

	var candidates []Kind
	var found []Kind

	// check args which should contains pod names
	for _, v := range GetDeployments() {
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
		o := v.(*Deployment)
		// check uid
		if uid != "" && !utils.Match(o.UID, uid, true) {
			continue
		}
		// check namespace
		if namespace != "" && !utils.Match(o.Namespace, namespace, true) {
			continue
		}

		// check label
		if label != "" {
			// one or more labels may be provided
			labelNotFound := false
			for _, l := range strings.Split(label, ";") {
				if !o.LabelFound(l) {
					labelNotFound = true
					break
				}
			}
			if labelNotFound {
				continue
			}
		}
		// found it if it reachs this point
		found = append(found, o)
	}

	return found
}

// PrintDeployments print deployments
func PrintDeployments(c *cli.Context) {
	PrintKinds(c, FilterDeployments, DeploymentHeaders)
}

// func PrintDeploymentsTabular(deployments []Kind, wide bool) {
// 	var ks []Kind
// 	for _, v := range deployments {
// 		ks = append(ks, v)
// 	}
// 	PrintTabular(DeploymentHeaders, ks, wide)
// }

// func PrintDeploymentsRaw(deployments []*Deployment) {
// 	for _, v := range deployments {
// 		PrintRaw(v)
// 	}
// }

// GetName implements kind.GetName()
func (k *Deployment) GetName() string {
	return k.Name
}

// PrintV implements kind.PrintV()
func (k *Deployment) PrintV(verbosity string) {
	// print Deployments
	fmt.Printf("# DEPLOYMENT\n")
	switch verbosity {
	case "v", "vv":
		utils.PrintStructInYAML(k)
	case "vvv":
		PrintRaw(k)
	}

	// print associated pods
	pods := k.GetPods()
	if len(pods) > 0 {
		fmt.Printf("# POD (%d)\n", len(pods))

		switch verbosity {
		case "v":
			PrintPodsTabular(pods, false)
		case "vv":
			utils.PrintStructInYAML(pods)
		case "vvv":
			PrintPodsRaw(pods)
		}
	}
}

// LabelFound check if the deployment has the label
func (k *Deployment) LabelFound(label string) bool {
	for _, l := range k.Labels {
		if l.Match(label) {
			return true
		}
	}
	return false
}

// DeploymentHeaders construct deployment header
func DeploymentHeaders(wide bool) string {
	headers := "Name | UID | Namespace | Repilicas | AvailableReplicas | ReadyReplicas | UpdatedReplicas | Age"
	if wide {
		return headers + " | CreationTimestamp | Conditions | Selectors | Labels"
	}
	return headers
}

// ToStr implements kind.ToStr()
func (k *Deployment) ToStr(wide bool) string {
	str := fmt.Sprintf("%s | %s | %s | %s | %s | %s | %s | %s",
		k.Name,
		k.UID,
		k.Namespace,
		k.Replicas,
		k.AvailableReplicas,
		k.ReadyReplicas,
		k.UpdatedReplicas,
		utils.Age(k.CreationTimestamp),
	)

	var conds []string
	for _, c := range k.Conditions {
		conds = append(conds, c.ToStr())
	}

	var labels []string
	for _, v := range k.Labels {
		labels = append(labels, v.ToStr())
	}

	var selectors []string
	for _, v := range k.Selectors {
		selectors = append(selectors, v.ToStr())
	}

	if wide {
		str += fmt.Sprintf(" | %s | %s | %s | %s",
			k.CreationTimestamp.Format(time.RFC3339),
			strings.Join(conds, ";"),
			strings.Join(selectors, ";"),
			strings.Join(labels, ";"),
		)
	}
	return str
}

// GetFilePath implements kind.GetFilePath()
func (k *Deployment) GetFilePath() string {
	return k.FilePath
}

// GetPods find pods managed by the deployment
func (k *Deployment) GetPods() []*Pod {
	var found []*Pod
	for _, v := range GetPods() {
		if LabelContains(v.Labels, k.Selectors) && v.Namespace == k.Namespace {
			found = append(found, v)
		}
	}
	return found
}

// DeploymentCondition struct
type DeploymentCondition struct {
	Type               string
	Status             string
	Reason             string
	Message            string
	LastTransitionTime time.Time
	LastUpdateTime     time.Time
}

// ToStr return deployment condition as string
func (k *DeploymentCondition) ToStr() string {
	return fmt.Sprintf("%s=%s", k.Type, k.Status)
}

// GetDeploymentConditions create DeploymentCondition objects
func GetDeploymentConditions(conditions []interface{}) []*DeploymentCondition {
	var conds []*DeploymentCondition

	for _, v := range conditions {
		c := utils.ToMap(v)
		o := &DeploymentCondition{
			c["type"].(string),
			c["status"].(string),
			c["reason"].(string),
			c["message"].(string),
			utils.ToTime(c["lastTransitionTime"].(string)),
			utils.ToTime(c["lastUpdateTime"].(string)),
		}
		conds = append(conds, o)
	}
	return conds
}
