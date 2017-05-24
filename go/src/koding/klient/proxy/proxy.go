package proxy

import (
    "github.com/koding/kite"

    "k8s.io/client-go/kubernetes"
    "k8s.io/client-go/rest"
)

type Proxy interface {

    Type() ProxyType

    // Methods allows a Proxy to provide a subset of the kite methods
    // that are supported by the klient instance, based on environment
    // characteristics at runtime.
    Methods() []string

    // List is a kite handler for the "proxy.list" call.
    //
    // Expects args of type ListRequest to filter response
    // from Kubernetes.
    //
    // Returns a ListResponse representing containers that klient
    // is responsible for proxying commands to.
    List(*kite.Request) (interface{}, error)

    // Exec is a kite handler for the "proxy.exec" call; it enables
    // other kites to execute remote commands on a contianer that this
    // klient is a proxy for.
    //
    // Expects args of type ExecRequest to specify how the execution
    // should be handled.
    //
    // Returns an ExecResponse representing a middle-man connection
    // that is proxying io to and from the remote container.
    Exec(*kite.Request) (interface{}, error)
}

// Factory provides a batteries included way of accessing a container proxy
// instance that is suited to klient's current environment and context.
func Factory() Proxy {
    if p, err := NewKubernetes(); err == nil {
        return p
    }

    return NewLocal()
}

func NewKubernetes() (Proxy, error) {

    // TODO (acbodine): Allow caller to override configuration values
    // to point at any Kubernetes endpoint. This will require adding
    // logic to create the connection externally instead of internal
    // to the cluster.

    // If klient is running in Kubernetes proxy mode, then we expect
    // to exist inside the same pod that comprises the Stack. Thus
    // our environment should be configured just like any other member
    // of this pod, and we will pull necessary config accordingly.
    conf, err := rest.InClusterConfig()
	if err != nil {
		return nil, err
	}

    // Initialize a client for our hosting Kubernetes API.
    cli, err := kubernetes.NewForConfig(conf)
    if err != nil {
        return nil, err
    }

    p := &KubernetesProxy{
        config:     conf,
        client:     cli,
    }

    return p, nil
}

func NewLocal() Proxy {
    return &LocalProxy{}
}
