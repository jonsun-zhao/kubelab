package kind

import (
	"fmt"
	"go-kubeutil/utils"
	"strings"
	"time"

	"github.com/codegangsta/cli"
)

// Services holds the created service objects
var Services []*Service

// Service struct
type Service struct {
	Name                  string
	UID                   string
	Namespace             string
	SelfLink              string
	ClusterIP             string
	ExternalTrafficPolicy string
	Type                  string
	Labels                []*Label
	Annotations           []*Annotation
	Ports                 []*ServicePort
	Selectors             []*Label
	ExternalIP            string
	CreationTimestamp     time.Time
	FilePath              string
}

// GetService get service by name and namespace
func GetService(name, namespace string) *Service {
	for _, v := range GetServices() {
		if v.Name == name && v.Namespace == namespace {
			return v
		}
	}
	return nil
}

// GetServices create service objects from files, or return Services slice if it is populated
func GetServices() []*Service {
	if len(Services) > 0 {
		return Services
	}
	for _, v := range GetKinds(GetServiceByFile, "service") {
		Services = append(Services, v.(*Service))
	}
	return Services
}

// GetServiceByFile create new service object from file
func GetServiceByFile(file string) Kind {
	k := new(Service)

	data := utils.ReadFileToMap(file)

	o := utils.ToMap(data)
	metadata := utils.ToMap(o["metadata"])
	spec := utils.ToMap(o["spec"])
	status := utils.ToMap(o["status"])

	k.Name = metadata["name"].(string)
	k.UID = metadata["uid"].(string)
	k.Namespace = metadata["namespace"].(string)
	k.SelfLink = metadata["selfLink"].(string)
	k.CreationTimestamp = utils.ToTime(metadata["creationTimestamp"].(string))
	k.Annotations = GetAnnotations(metadata["annotations"])
	k.Labels = GetLabels(metadata["labels"])

	k.ClusterIP = spec["clusterIP"].(string)
	if v, ok := spec["externalTrafficPolicy"]; ok {
		k.ExternalTrafficPolicy = v.(string)
	}
	if v, ok := spec["type"]; ok {
		k.Type = v.(string)
	}
	k.Ports = GetServicePorts(spec["ports"].([]interface{}))
	k.Selectors = GetLabels(spec["selector"])

	if v, ok := status["loadBalancer"]; ok {
		// utils.PrintStructInYAML(v)
		ingMap := utils.ToMap(v)

		if len(ingMap) > 0 {
			pair := ingMap["ingress"].([]interface{})[0]
			k.ExternalIP = utils.ToMap(pair)["ip"].(string)
		}
	}

	k.FilePath = file
	return k
}

// FilterServices filter services by flags
func FilterServices(c *cli.Context) []Kind {
	args := c.Args()
	uid := c.String("uid")
	label := c.String("label")
	namespace := c.String("namespace")
	selector := c.String("selector")

	var candidates []Kind
	var found []Kind

	// check args which should contains pod names
	for _, v := range GetServices() {
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
		o := v.(*Service)
		// check uid
		if uid != "" && !utils.Match(o.UID, uid, true) {
			continue
		}
		// check namespace
		if namespace != "" && !utils.Match(o.Namespace, namespace, true) {
			continue
		}
		// check label(k)
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
		// check selector
		if selector != "" {
			labelNotFoundInSelector := false
			for _, l := range strings.Split(selector, ";") {
				if !o.LabelFoundInSelector(l) {
					labelNotFoundInSelector = true
					break
				}
			}
			if labelNotFoundInSelector {
				continue
			}
		}
		// found it if it reachs this point
		found = append(found, o)
	}

	return found
}

// PrintServices print services
func PrintServices(c *cli.Context) {
	PrintKinds(c, FilterServices, ServiceHeaders)
}

// PrintServicesTabular print services in tabular form
func PrintServicesTabular(services []*Service, wide bool) {
	var ks []Kind
	for _, v := range services {
		ks = append(ks, v)
	}
	PrintTabular(ServiceHeaders, ks, wide)
}

// PrintServicesRaw print raw service JSON files
func PrintServicesRaw(services []*Service) {
	for _, v := range services {
		PrintRaw(v)
	}
}

// GetName implements kind.GetName()
func (k *Service) GetName() string {
	return k.Name
}

// PrintV implements kind.PrintV()
func (k *Service) PrintV(verbosity string) {
	// print service
	fmt.Printf("# SERVICE\n")
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

// LabelFound check if the service has the label
func (k *Service) LabelFound(label string) bool {
	for _, v := range k.Labels {
		if v.Match(label) {
			return true
		}
	}
	return false
}

// LabelFoundInSelector check if the service's selector has the label
func (k *Service) LabelFoundInSelector(label string) bool {
	for _, v := range k.Selectors {
		if v.Match(label) {
			return true
		}
	}
	return false
}

// ServiceHeaders construct header string
func ServiceHeaders(wide bool) string {
	headers := "Name | UID | Namespace | ClusterIP | ExternalIP | Type | Ports | Age"
	if wide {
		return headers + " | CreationTimestamp | Selector | Label"
	}
	return headers
}

// ToStr return service detail as a string
func (k *Service) ToStr(wide bool) string {
	var labels []string
	for _, v := range k.Labels {
		labels = append(labels, v.ToStr())
	}
	labelStr := strings.Join(labels, ";")

	var selectors []string
	for _, v := range k.Selectors {
		selectors = append(selectors, v.ToStr())
	}
	selectorStr := strings.Join(selectors, ";")

	var ports []string
	for _, v := range k.Ports {
		ports = append(ports, v.ToStr())
	}
	portStr := strings.Join(ports, ";")

	str := fmt.Sprintf("%s | %s | %s | %s | %s | %s | %s | %s",
		k.Name,
		k.UID,
		k.Namespace,
		k.ClusterIP,
		k.ExternalIP,
		k.Type,
		portStr,
		utils.Age(k.CreationTimestamp),
	)
	if wide {
		str += fmt.Sprintf(" | %s | %s | %s",
			utils.Time(k.CreationTimestamp), selectorStr, labelStr)
	}
	return str
}

// GetFilePath implement kind.GetFilePath()
func (k *Service) GetFilePath() string {
	return k.FilePath
}

// GetPods fetch pods that served by this service
func (k *Service) GetPods() []*Pod {
	var found []*Pod
	for _, p := range GetPods() {
		if LabelContains(p.Labels, k.Selectors) && p.Namespace == k.Namespace {
			found = append(found, p)
		}
	}
	return found
}

// ServicePort struct
type ServicePort struct {
	Name       string
	NodePort   string
	Port       string
	Protocol   string
	TargetPort string
}

// GetServicePorts create service ports
func GetServicePorts(ports []interface{}) []*ServicePort {
	var servicePorts []*ServicePort

	for _, v := range ports {
		a := utils.ToMap(v)

		o := &ServicePort{
			NodePort:   "none",
			TargetPort: "none",
			Port:       utils.FloatToString(a["port"].(float64)),
			Protocol:   a["protocol"].(string),
		}

		if v, ok := a["name"]; ok {
			o.Name = v.(string)
		}

		if v, ok := a["nodePort"]; ok {
			o.NodePort = utils.FloatToString(v.(float64))
		}

		if v, ok := a["targetPort"]; ok {
			switch v.(type) {
			case float64:
				o.TargetPort = utils.FloatToString(v.(float64))
			case string:
				o.TargetPort = v.(string)
			}
		}

		servicePorts = append(servicePorts, o)
	}

	return servicePorts
}

// ToStr return service port detail as a string
func (sp *ServicePort) ToStr() string {
	return fmt.Sprintf("Port=%s;NodePort=%s;TargetPort=%s", sp.Port, sp.NodePort, sp.TargetPort)
}
