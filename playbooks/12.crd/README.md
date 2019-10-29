# Custom Resource Definition (CRD)

## Custom resources

A resource is an endpoint in the Kubernetes API that stores a collection of [API objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/) of a certain kind. For example, the built-in `pods` resource contains a collection of Pod objects.

A `custom resource` is an extension of the Kubernetes API that is not necessarily available in a default Kubernetes installation. It represents a customization of a particular Kubernetes installation. However, many core Kubernetes functions are now built using custom resources, making Kubernetes more modular.

`Custom resources` can appear and disappear in a running cluster through dynamic registration, and cluster admins can update custom resources independently of the cluster itself. Once a custom resource is installed, users can create and access its objects using kubectl, just as they do for built-in resources like `Pods`.

## Custom controllers

On their own, `custom resources` simply let you store and retrieve structured data. When you combine a custom resource with a custom controller, custom resources provide a true declarative API.

A [declarative API](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/#understanding-kubernetes-objects) allows you to declare or specify the desired state of your resource and tries to keep the current state of Kubernetes objects in sync with the desired state. The controller interprets the structured data as a record of the user’s desired state, and continually maintains this state.

You can deploy and update a custom controller on a running cluster, **independently of the cluster’s own lifecycle**. Custom controllers can work with any kind of resource, but they are especially effective when combined with custom resources. The `Operator pattern` combines custom resources and custom controllers. You can use custom controllers to encode domain knowledge for specific applications into an extension of the Kubernetes API.
