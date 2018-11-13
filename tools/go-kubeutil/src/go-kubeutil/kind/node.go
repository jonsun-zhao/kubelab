package kind

import (
	"fmt"
	"go-kubeutil/utils"
	"strings"
	"time"

	"github.com/codegangsta/cli"
)

// Nodes holds the created node objects
var Nodes []*Node

// Node Struct
type Node struct {
	Name              string
	UID               string
	PodCIDR           string
	SelfLink          string
	ExternalID        string
	Labels            []*Label
	Annotations       []*Annotation
	Addresses         []*NodeAddress
	Conditions        []*NodeCondition
	CreationTimestamp time.Time
	FilePath          string
}

// GetNode get node by name
func GetNode(name string) *Node {
	for _, v := range GetNodes() {
		if v.Name == name {
			return v
		}
	}
	return nil
}

// GetNodes create nodes from files
func GetNodes() []*Node {
	if len(Nodes) > 0 {
		return Nodes
	}
	for _, v := range GetKinds(GetNodeByFile, "node") {
		Nodes = append(Nodes, v.(*Node))
	}
	return Nodes
}

// GetNodeByFile create node from file
func GetNodeByFile(file string) Kind {
	k := new(Node)

	data := utils.ReadFileToMap(file)

	o := utils.ToMap(data)
	metadata := utils.ToMap(o["metadata"])
	spec := utils.ToMap(o["spec"])
	status := utils.ToMap(o["status"])

	k.Name = metadata["name"].(string)
	k.UID = metadata["uid"].(string)
	k.SelfLink = metadata["selfLink"].(string)
	k.CreationTimestamp = utils.ToTime(metadata["creationTimestamp"].(string))
	k.Labels = GetLabels(metadata["labels"])
	k.Annotations = GetAnnotations(metadata["annotations"])

	k.PodCIDR = spec["podCIDR"].(string)
	if v, ok := spec["externalID"]; ok {
		k.ExternalID = v.(string)
	}
	k.Addresses = GetNodeAddresses(status["addresses"].([]interface{}))
	k.Conditions = GetNodeConditions(status["conditions"].([]interface{}))

	k.FilePath = file
	return k
}

// FilterNodes filter nodes by flags
func FilterNodes(c *cli.Context) []Kind {
	args := c.Args()
	uid := c.String("uid")
	label := c.String("label")
	ready := c.String("ready")

	var candidates []Kind
	var found []Kind

	// check args which should contains pod names
	for _, k := range GetNodes() {
		if c.NArg() > 0 {
			for _, a := range args {
				if utils.Match(k.Name, a, true) {
					candidates = append(candidates, k)
				}
			}
		} else {
			candidates = append(candidates, k)
		}
	}

	for _, v := range candidates {
		o := v.(*Node)
		// check uid
		if uid != "" && !utils.Match(o.UID, uid, true) {
			// fmt.Println("***" + uid)
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

// PrintNodes print nodes
func PrintNodes(c *cli.Context) {
	PrintKinds(c, FilterNodes, NodeHeaders)
}

// PrintNodesTabular print nodes in tabular form
func PrintNodesTabular(nodes []*Node, wide bool) {
	var ks []Kind
	for _, v := range nodes {
		ks = append(ks, v)
	}
	PrintTabular(NodeHeaders, ks, wide)
}

// PrintNodesRaw print raw node JSON files
func PrintNodesRaw(nodes []*Node) {
	for _, v := range nodes {
		PrintRaw(v)
	}
}

// GetName implement kind.GetName()
func (k *Node) GetName() string {
	return k.Name
}

// PrintV implement kind.PrintV()
func (k *Node) PrintV(verbosity string) {
	// print node
	fmt.Printf("# NODE\n")
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

// LabelFound check if the node has the given label
func (k *Node) LabelFound(label string) bool {
	for _, l := range k.Labels {
		if l.Match(label) {
			return true
		}
	}
	return false
}

// Ready check if the node is ready
func (k *Node) Ready() bool {
	// ready := false
	for _, c := range k.Conditions {
		if c.Type == "Ready" && c.Status == "True" {
			return true
		}
	}
	return false
}

// NodeHeaders construct header string
func NodeHeaders(wide bool) string {
	headers := "Name | UID | InstanceID | Address | Ready | Age"
	if wide {
		return headers + " | CreationTimestamp | PodCIDR | Label"
	}
	return headers
}

// ToStr implement kind.ToStr()
func (k *Node) ToStr(wide bool) string {
	var labels []string
	for _, l := range k.Labels {
		labels = append(labels, l.ToStr())
	}
	labelStr := strings.Join(labels, ";")

	var addresses []string
	for _, a := range k.Addresses {
		if a.AddressType != "Hostname" {
			addresses = append(addresses, a.ToStr())
		}
	}
	addressStr := strings.Join(addresses, ";")

	var conditionStr string
	for _, c := range k.Conditions {
		if c.Type == "Ready" {
			conditionStr = c.Status
			break
		}
	}

	str := fmt.Sprintf("%s | %s | %s | %s | %s | %s",
		k.Name,
		k.UID,
		k.ExternalID,
		addressStr,
		conditionStr,
		utils.Age(k.CreationTimestamp),
	)
	if wide {
		str += fmt.Sprintf(" | %s | %s | %s",
			utils.Time(k.CreationTimestamp), k.PodCIDR, labelStr)
	}
	return str
}

// GetFilePath implement kind.GetFilePath()
func (k *Node) GetFilePath() string {
	return k.FilePath
}

// GetPods find pods in the node
func (k *Node) GetPods() []*Pod {
	var found []*Pod
	for _, v := range GetPods() {
		if v.NodeName == k.Name {
			found = append(found, v)
		}
	}
	return found
}

// NodeAddress struct
type NodeAddress struct {
	AddressType string
	Address     string
}

// GetNodeAddresses create GetNodeAddress objects
func GetNodeAddresses(addresses []interface{}) []*NodeAddress {
	var nodeAddresses []*NodeAddress

	for _, v := range addresses {
		a := utils.ToMap(v)

		o := &NodeAddress{
			a["type"].(string),
			a["address"].(string),
		}
		nodeAddresses = append(nodeAddresses, o)
	}

	return nodeAddresses
}

// ToStr return GetNodeAddresses detail as a string
func (k *NodeAddress) ToStr() string {
	return k.AddressType + "=" + k.Address
}

// NodeCondition struct
type NodeCondition struct {
	Type               string
	Status             string
	Reason             string
	Message            string
	LastTransitionTime time.Time
	LastHeartbeatTime  time.Time
}

// GetNodeConditions create GetNodeCondition objects
func GetNodeConditions(conditions []interface{}) []*NodeCondition {
	var nodeConditions []*NodeCondition

	for _, v := range conditions {
		c := utils.ToMap(v)
		o := &NodeCondition{
			c["type"].(string),
			c["status"].(string),
			c["reason"].(string),
			c["message"].(string),
			utils.ToTime(c["lastTransitionTime"].(string)),
			utils.ToTime(c["lastHeartbeatTime"].(string)),
		}
		nodeConditions = append(nodeConditions, o)
	}
	return nodeConditions
}
