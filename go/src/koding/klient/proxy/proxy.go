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
    // Returns a *MachinesResponse representing machines that klient
    // is responsible for proxying commands to.
    List(*kite.Request) (interface{}, error)

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
    p := &KubernetesProxy{
        client: nil,
    }

    // If klient is running in Kubernetes proxy mode, then we expect
    // to exist inside the same pod that comprises the Stack. Thus
    // our environment should be configured just like any other member
    // of this pod, and we will pull necessary config accordingly.
    conf, err := rest.InClusterConfig()
	if err != nil {
		return nil, err
	}

    // Initialize a client for our hosting Kubernetes API.
    p.client, err = kubernetes.NewForConfig(conf)
    if err != nil {
        return nil, err
    }

    return p, nil
}

func NewLocal() Proxy {
    return &LocalProxy{}
}
