package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/helm"

	appsv1 "k8s.io/api/apps/v1"
)

func TestFortioTemplateRendersContainerImage(t *testing.T) {
	// Path to the helm chart we will test
	helmChartPath := "../charts/fortio"

	// Setup the args. For this test, we will set the following input values:
	// - image=nginx:1.15.8
	options := &helm.Options{
		SetValues: map[string]string{
			"image.repository": "fortio",
			"image.tag":        "local",
			"service.type":     "gce",
		},
	}

	// Run RenderTemplate to render the template and capture the output.
	output := helm.RenderTemplate(t,
		options, helmChartPath, []string{"templates/deployment.yaml"})

	// Now we use kubernetes/client-go library to render the template output into the Pod struct. This will
	// ensure the Pod resource is rendered correctly.
	var dep appsv1.Deployment
	helm.UnmarshalK8SYaml(t, output, &dep)

	// Finally, we verify the pod spec is set to the expected container image value
	expectedContainerImage := "fortio:local"
	podContainers := dep.Spec.Template.Spec.Containers
	if podContainers[0].Image != expectedContainerImage {
		t.Fatalf("Rendered container image (%s) is not expected (%s)", podContainers[0].Image, expectedContainerImage)
	}
}
