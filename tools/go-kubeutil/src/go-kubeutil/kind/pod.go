package kind

import (
	"fmt"
	"go-kubeutil/utils"
	"strings"
	"time"

	"github.com/codegangsta/cli"
)

// Pods holds the created pod objects
var Pods []*Pod

// Pod ...
type Pod struct {
	Name                 string `json:"name,omitempty"`
	UID                  string
	Namespace            string
	DNSPolicy            string
	HostNetwork          bool
	RestartPolicy        string
	SelfLink             string
	NodeName             string
	Annotations          []*Annotation
	Labels               []*Label
	PodIP                string
	QosClass             string
	StartTime            time.Time // "2018-06-28T16:05:29Z"
	PodContainerStatuses []*PodContainerStatus
	PodConditions        []*PodCondition
	Phase                string
	ServiceAccount       string
	CreationTimestamp    time.Time
	FilePath             string
}

// GetPod get pod by name and namespace
func GetPod(name, namespace string) *Pod {
	for _, v := range GetPods() {
		if v.Name == name && v.Namespace == namespace {
			return v
		}
	}
	return nil
}

// GetPods create pod objects from JSONs
func GetPods() []*Pod {
	if len(Pods) > 0 {
		return Pods
	}
	for _, v := range GetKinds(GetPodByFile, "pod") {
		Pods = append(Pods, v.(*Pod))
	}
	return Pods
}

// GetPodByFile create pod object from JSON
func GetPodByFile(file string) Kind {
	p := new(Pod)

	data := utils.ReadFileToMap(file)

	// convert data (interface{}) to map[string]interface{}
	o := utils.ToMap(data)
	metadata := utils.ToMap(o["metadata"])
	spec := utils.ToMap(o["spec"])
	status := utils.ToMap(o["status"])

	p.Name = metadata["name"].(string)
	// fmt.Println(p.Name)

	p.UID = metadata["uid"].(string)
	p.Namespace = metadata["namespace"].(string)
	p.CreationTimestamp = utils.ToTime(metadata["creationTimestamp"].(string))
	p.SelfLink = metadata["selfLink"].(string)
	// p.Node = GetNode(spec["nodeName"].(string))
	p.NodeName = spec["nodeName"].(string)
	p.DNSPolicy = spec["dnsPolicy"].(string)
	p.RestartPolicy = spec["restartPolicy"].(string)
	p.StartTime = utils.ToTime(status["startTime"].(string))

	if v, ok := spec["hostNetwork"]; ok {
		p.HostNetwork = v.(bool)
	}
	if v, ok := metadata["annotations"]; ok {
		p.Annotations = GetAnnotations(v)
	}
	if v, ok := metadata["labels"]; ok {
		p.Labels = GetLabels(v)
	}
	if v, ok := status["podIP"]; ok {
		p.PodIP = v.(string)
	}
	if v, ok := status["qosClass"]; ok {
		p.QosClass = v.(string)
	}
	if v, ok := status["containerStatuses"]; ok {
		p.PodContainerStatuses = GetPodContainerStatuses(v.([]interface{}))
	}
	if v, ok := status["conditions"]; ok {
		p.PodConditions = GetPodConditions(v.([]interface{}))
	}
	if v, ok := status["phase"]; ok {
		p.Phase = v.(string)
	}
	if v, ok := spec["serviceAccount"]; ok {
		p.ServiceAccount = v.(string)
	}

	p.FilePath = file
	return p
}

// FilterPods filter pods by flags
func FilterPods(c *cli.Context) []Kind {

	args := c.Args()
	uid := c.String("uid")
	namespace := c.String("namespace")
	node := c.String("node")
	service := c.String("service")
	label := c.String("label")
	ready := c.String("ready")

	var candidates []Kind
	var found []Kind

	// check args which should contains pod names
	for _, v := range GetPods() {
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
		o := v.(*Pod)
		// check uid
		if uid != "" && !utils.Match(o.UID, uid, true) {
			continue
		}
		// check namespace
		if namespace != "" && !utils.Match(o.Namespace, namespace, true) {
			continue
		}
		// check node
		if node != "" && !utils.Match(o.NodeName, node, true) {
			continue
		}
		// check service
		if service != "" {
			s := GetService(service, o.Namespace)
			if s == nil {
				continue
			}
			if !LabelContains(o.Labels, s.Selectors) {
				continue
			}
		}
		// check label(s)
		if label != "" {
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
		// check readiness
		if ready != "" {
			if ready == "true" && !o.Ready() {
				continue
			}
			if ready == "false" && o.Ready() {
				continue
			}
		}
		// found it if it reachs this point
		found = append(found, o)
	}

	return found
}

// PrintPods print pods
func PrintPods(c *cli.Context) {
	PrintKinds(c, FilterPods, PodHeaders)
}

// PrintPodsTabular print pods in tabular form
func PrintPodsTabular(pods []*Pod, wide bool) {
	var ks []Kind
	for _, v := range pods {
		ks = append(ks, v)
	}
	PrintTabular(PodHeaders, ks, false)
}

// PrintPodsRaw print raw pod JSON files
func PrintPodsRaw(pods []*Pod) {
	for _, v := range pods {
		PrintRaw(v)
	}
}

// GetName implememnt kind.GetName()
func (k *Pod) GetName() string {
	return k.Name
}

// PrintV implment kind.PrintV()
func (k *Pod) PrintV(verbosity string) {
	// print pod
	fmt.Printf("# POD\n")
	switch verbosity {
	case "v", "vv":
		utils.PrintStructInYAML(k)
	case "vvv":
		PrintRaw(k)
	}

	// print associated node
	fmt.Printf("# NODE\n")
	node := GetNode(k.NodeName)
	switch verbosity {
	case "v":
		PrintNodesTabular([]*Node{node}, false)
	case "vv":
		utils.PrintStructInYAML(node)
	case "vvv":
		PrintRaw(node)
	}

	// print associated services
	services := k.GetServices()
	if len(services) > 0 {
		fmt.Printf("# SERVICE (%d)\n", len(services))
		switch verbosity {
		case "v":
			PrintServicesTabular(services, false)
		case "vv":
			utils.PrintStructInYAML(services)
		case "vvv":
			PrintServicesRaw(services)
		}
	}

}

// PodHeaders construct header string
func PodHeaders(wide bool) string {
	headers := "Name | UID | Namespace | PodIP | Node | Phase | Ready | Age"
	if wide {
		return headers + " | CreationTimestamp | ContainerStatus | Label"
	}
	return headers
}

// ToStr implement kind.ToStr()
func (k *Pod) ToStr(wide bool) string {
	var labels []string
	for _, l := range k.Labels {
		labels = append(labels, l.ToStr())
	}
	labelStr := strings.Join(labels, ";")

	var containerStatuses []string
	for _, s := range k.PodContainerStatuses {
		containerStatuses = append(containerStatuses, s.ToStr())
	}
	containerStatusStr := strings.Join(containerStatuses, ";")

	var conditionStr string
	for _, c := range k.PodConditions {
		if c.Type == "Ready" {
			conditionStr = c.Status
			break
		}
	}

	str := fmt.Sprintf("%s | %s | %s | %s | %s | %s | %s | %s",
		k.Name,
		k.UID,
		k.Namespace,
		k.PodIP,
		k.NodeName,
		k.Phase,
		conditionStr,
		utils.Age(k.CreationTimestamp),
	)
	if wide {
		str += fmt.Sprintf(" | %s | %s | %s",
			utils.Time(k.CreationTimestamp), containerStatusStr, labelStr)
	}
	return str
}

// LabelFound check if the pod has the label
func (k *Pod) LabelFound(label string) bool {
	for _, l := range k.Labels {
		if l.Match(label) {
			return true
		}
	}
	return false
}

// Ready check if the pod is ready
func (k *Pod) Ready() bool {
	// ready := false
	for _, c := range k.PodConditions {
		if c.Type == "Ready" && c.Status == "True" {
			return true
		}
	}
	return false
}

// GetFilePath implement kind.GetFilePath()
func (k *Pod) GetFilePath() string {
	return k.FilePath
}

// GetServices find the services that serve this pod
func (k *Pod) GetServices() []*Service {
	var found []*Service
	for _, v := range GetServices() {
		if LabelContains(k.Labels, v.Selectors) && (k.Namespace == v.Namespace) {
			found = append(found, v)
		}
	}
	return found
}

// PodContainerStatus struct
type PodContainerStatus struct {
	Name        string
	ContainerID string
	Image       string
	ImageID     string
	Ready       bool
	State       string
}

// GetPodContainerStatuses create PodContainerStatus object
func GetPodContainerStatuses(pcs []interface{}) []*PodContainerStatus {
	var podContainerStatuses []*PodContainerStatus

	for _, v := range pcs {
		s := utils.ToMap(v)

		// "state": {
		// 	"terminated": {
		// 					"containerID": "docker://201271fc1ed15105d71dc04c02b09a72dc00d62eb929004e81c8a463b9fb021f",
		// 					"exitCode": 0,
		// 					"finishedAt": "2018-06-28T23:02:32Z",
		// 					"reason": "Completed",
		// 					"startedAt": "2018-06-28T23:02:25Z"
		// 	}
		// }

		var state string
		for k := range utils.ToMap(s["state"]) {
			state = k
			break // shouldn't have more than one state
		}

		o := &PodContainerStatus{
			s["name"].(string),
			s["containerID"].(string),
			s["image"].(string),
			s["imageID"].(string),
			s["ready"].(bool),
			state,
		}
		podContainerStatuses = append(podContainerStatuses, o)
	}

	return podContainerStatuses
}

// ToStr return PodContainerStatus detail as a string
func (c *PodContainerStatus) ToStr() string {
	return fmt.Sprintf("%s[%s]", c.Name, c.State)
}

// PodCondition struct
type PodCondition struct {
	Type               string
	Status             string
	Reason             string
	Message            string
	LastTransitionTime time.Time
}

// GetPodConditions create PodCondition object
func GetPodConditions(pc []interface{}) []*PodCondition {
	var podConditions []*PodCondition

	for _, v := range pc {
		c := utils.ToMap(v)

		o := &PodCondition{
			Type:               c["type"].(string),
			Status:             c["status"].(string),
			LastTransitionTime: utils.ToTime(c["lastTransitionTime"].(string)),
		}
		if v, ok := c["reason"]; ok {
			o.Reason = v.(string)
		}
		if v, ok := c["message"]; ok {
			o.Message = v.(string)
		}
		podConditions = append(podConditions, o)
	}

	return podConditions
}
