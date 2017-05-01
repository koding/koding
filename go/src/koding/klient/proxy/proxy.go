package proxy

import (
    "fmt"

    "github.com/koding/kite"
    "k8s.io/apimachinery/pkg/runtime/serializer"
    "k8s.io/client-go/kubernetes"
    "k8s.io/client-go/kubernetes/scheme"
    "k8s.io/client-go/pkg/api/v1"
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

    // Exec allows a Proxy to extend the "os.exec" kite handler, so
    // that commands are proxied to the remote container.
    Exec(*ExecRequest) error
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
        config: nil,
        client: nil,
        rest:   nil,
    }

    // If klient is running in Kubernetes proxy mode, then we expect
    // to exist inside the same pod that comprises the Stack. Thus
    // our environment should be configured just like any other member
    // of this pod, and we will pull necessary config accordingly.
    config, err := rest.InClusterConfig()
	if err != nil {
		return nil, err
	}
    p.config = config

    gv := v1.SchemeGroupVersion
	p.config.GroupVersion = &gv
	p.config.APIPath = "/api"
	config.NegotiatedSerializer = serializer.DirectCodecFactory{
        CodecFactory: scheme.Codecs,
    }

	if p.config.UserAgent == "" {
		p.config.UserAgent = rest.DefaultKubernetesUserAgent()
	}

    // Initialize a client for our hosting Kubernetes API.
    p.client, err = kubernetes.NewForConfig(p.config)
    if err != nil {
        return nil, err
    }

    p.rest, err = rest.RESTClientFor(p.config)
    if err != nil {
        fmt.Println(err)
        return nil, err
    }

    return p, nil
}

func NewLocal() Proxy {
    return &LocalProxy{}
}
