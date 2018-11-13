package kind

import (
	"fmt"
	"go-kubeutil/utils"
	"time"

	"github.com/codegangsta/cli"
)

// Ingresses holds the created ingress object
var Ingresses []*Ingress

// Ingress struct
type Ingress struct {
	Name              string
	UID               string
	Namespace         string
	SelfLink          string
	Labels            []*Label
	Annotations       []*Annotation
	Backend           *IngressBackend
	Rules             []*IngressRule
	TLSCerts          []*IngressTLSCert
	IP                string
	CreationTimestamp time.Time
	FilePath          string
}

// GetIngress get ingress by name and namespace
func GetIngress(name, namespace string) *Ingress {
	for _, v := range GetIngresses() {
		if v.Name == name && v.Namespace == namespace {
			return v
		}
	}
	return nil
}

// GetIngresses create ingress objects from files
func GetIngresses() []*Ingress {
	if len(Ingresses) > 0 {
		return Ingresses
	}
	for _, v := range GetKinds(GetIngressByFile, "ingress") {
		Ingresses = append(Ingresses, v.(*Ingress))
	}
	return Ingresses
}

// GetIngressByFile create ingress from file
func GetIngressByFile(file string) Kind {
	k := new(Ingress)

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
	k.Annotations = GetAnnotations(metadata["annotations"])
	// k.Labels = GetLabels(metadata["labels"])

	if v, ok := spec["backend"]; ok {
		k.Backend = GetIngressBackend(v)
	}

	if v, ok := spec["rules"]; ok {
		k.Rules = GetIngressRules(v.([]interface{}))
	}

	if v, ok := spec["tls"]; ok {
		k.TLSCerts = GetIngressTLSCerts(v.([]interface{}))
	}

	if v, ok := status["loadBalancer"]; ok {
		// utils.PrintStructInYAML(v)
		ingMap := utils.ToMap(v)

		if len(ingMap) > 0 {
			pair := ingMap["ingress"].([]interface{})[0]
			k.IP = utils.ToMap(pair)["ip"].(string)
		}
	}

	k.FilePath = file
	return k
}

// GetIngressBackend create IngressBackend
func GetIngressBackend(k interface{}) *IngressBackend {
	o := utils.ToMap(k)
	return &IngressBackend{
		ServiceName: o["serviceName"].(string),
		ServicePort: utils.FloatToString(o["servicePort"].(float64)),
	}
}

// GetIngressRules create IngressRule
func GetIngressRules(rules []interface{}) []*IngressRule {
	var ingressRules []*IngressRule

	for _, v := range rules {
		a := utils.ToMap(v)

		httpPaths := utils.ToMap(a["http"])["paths"].([]interface{})

		o := &IngressRule{
			HTTPPaths: GetIngressRuleHTTPPaths(httpPaths),
		}

		if v, ok := a["host"]; ok {
			o.Host = v.(string)
		}

		ingressRules = append(ingressRules, o)
	}

	return ingressRules
}

// GetIngressTLSCerts create IngressTLSCert
func GetIngressTLSCerts(certs []interface{}) []*IngressTLSCert {
	var ingressTLSCerts []*IngressTLSCert

	for _, v := range certs {
		c := utils.ToMap(v)
		o := &IngressTLSCert{
			c["secretName"].(string),
		}
		ingressTLSCerts = append(ingressTLSCerts, o)
	}
	return ingressTLSCerts
}

// GetIngressRuleHTTPPaths create IngressRuleHTTPPath
func GetIngressRuleHTTPPaths(paths []interface{}) []*IngressRuleHTTPPath {
	var ingressRuleHTTPPaths []*IngressRuleHTTPPath

	for _, v := range paths {
		p := utils.ToMap(v)
		backend := p["backend"]

		o := &IngressRuleHTTPPath{
			Backend: GetIngressBackend(backend),
		}
		if v, ok := p["path"]; ok {
			o.Path = v.(string)
		}
		ingressRuleHTTPPaths = append(ingressRuleHTTPPaths, o)
	}
	return ingressRuleHTTPPaths
}

// FilterIngresses filter ingress by flags
func FilterIngresses(c *cli.Context) []Kind {
	args := c.Args()
	uid := c.String("uid")
	// label := c.String("label")
	namespace := c.String("namespace")

	var candidates []Kind
	var found []Kind

	// check args which should contains pod names
	for _, v := range GetIngresses() {
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
		o := v.(*Ingress)
		// check uid
		if uid != "" && !utils.Match(o.UID, uid, true) {
			continue
		}
		// check namespace
		if namespace != "" && !utils.Match(o.Namespace, namespace, true) {
			continue
		}
		// found it if it reachs this point
		found = append(found, o)
	}

	return found
}

// PrintIngresses print ingresses
func PrintIngresses(c *cli.Context) {
	PrintKinds(c, FilterIngresses, IngressHeaders)
}

// func PrintIngressesTabular(ingresses []*Ingress, wide bool) {
// 	var ks []Kind
// 	for _, v := range ingresses {
// 		ks = append(ks, v)
// 	}
// 	PrintTabular(IngressHeaders, ks, wide)
// }

// func PrintIngressesRaw(ingresses []*Ingress) {
// 	for _, v := range ingresses {
// 		PrintRaw(v)
// 	}
// }

// GetName implement kind.GetName()
func (k *Ingress) GetName() string {
	return k.Name
}

// PrintV implememt kind.PrintV()
func (k *Ingress) PrintV(verbosity string) {
	// print ingresses
	fmt.Printf("# Ingress\n")
	switch verbosity {
	case "v", "vv":
		utils.PrintStructInYAML(k)
	case "vvv":
		PrintRaw(k)
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

// IngressHeaders construct ingress header
func IngressHeaders(wide bool) string {
	headers := "Name | UID | Namespace | Backend | IP | Age"
	if wide {
		return headers + " | CreationTimestamp | Rules"
	}
	return headers
}

// ToStr implement kind.ToStr()
func (k *Ingress) ToStr(wide bool) string {
	str := fmt.Sprintf("%s | %s | %s | %s | %s | %s",
		k.Name,
		k.UID,
		k.Namespace,
		k.Backend.ToStr(),
		k.IP,
		utils.Age(k.CreationTimestamp),
	)

	ruleStr := ""
	for _, v := range k.Rules {
		ruleStr += v.ToStr()
	}

	if wide {
		str += fmt.Sprintf(" | %s | %s", utils.Time(k.CreationTimestamp), ruleStr)
	}
	return str
}

// GetFilePath implement kind.GetFilePath()
func (k *Ingress) GetFilePath() string {
	return k.FilePath
}

// GetServices find services selected by the ingress
func (k *Ingress) GetServices() []*Service {
	var backendServiceNames []string
	var found []*Service

	if k.Backend != nil {
		backendServiceNames = append(backendServiceNames, k.Backend.ServiceName)
	}

	for _, r := range k.Rules {
		for _, b := range r.GetBackends() {
			backendServiceNames = append(backendServiceNames, b.ServiceName)
		}
	}

	for _, v := range GetServices() {
		if utils.Include(backendServiceNames, v.Name) && k.Namespace == v.Namespace {
			found = append(found, v)
		}
	}
	return found
}

// IngressRule struct
type IngressRule struct {
	HTTPPaths []*IngressRuleHTTPPath
	Host      string
}

// ToStr return ingress rule detail as string
func (k *IngressRule) ToStr() string {
	str := ""
	for _, v := range k.HTTPPaths {
		str += v.ToStr()
	}
	return fmt.Sprintf("{host=[%s]paths=[%s]}", k.Host, str)
}

// GetBackends get backends from ingress rule
func (k *IngressRule) GetBackends() []*IngressBackend {
	var backends []*IngressBackend
	for _, v := range k.HTTPPaths {
		backends = append(backends, v.Backend)
	}
	return backends
}

// IngressRuleHTTPPath struct
type IngressRuleHTTPPath struct {
	Backend *IngressBackend
	Path    string
}

// ToStr return http path as string
func (k *IngressRuleHTTPPath) ToStr() string {
	return fmt.Sprintf("(%s=>%s)", k.Path, k.Backend.ToStr())
}

// IngressBackend struct
type IngressBackend struct {
	ServiceName string
	ServicePort string
}

// ToStr return backend as string
func (k *IngressBackend) ToStr() string {
	if k == nil {
		return ""
	}
	return fmt.Sprintf("%s:%s", k.ServiceName, k.ServicePort)
}

// IngressTLSCert struct
type IngressTLSCert struct {
	SecretName string
}
