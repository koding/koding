package proxy

import (
    "koding/klient/info"

    "github.com/koding/kite"
)

type InfoResponse struct {
    *info.InfoResponse

    // Supports identifies which kite methods that klient currently can
	// respond to. This changes based on what environment klient is running
	// in (i.e. In Kubernetes for example, we don't support fs.* yet)
	Supports		[]string	`json:"supports"`

    // ContainerProxy determines how a klient kite accesses the container(s)
	// it is bound to. This controls proxy logic for specific kite methods
	// in klient, delegating to a 3rd party service for the transport. In the
	// case when we have container based stacks; klient is not in the same
	// context as it's containers(s).
	ContainerProxy	ProxyType	`json:"containerproxy"`
}

// Info is a kite handler for the "klient.info" call. It is an extension
// of the existing info.Info kite handler.
//
// Returns an InfoResponse which is a wrapper type for info.InfoResponse.
func (p *KubernetesProxy) Info(r *kite.Request) (interface{}, error) {
    iface, err := info.Info(r)
    if err != nil {
        return nil, err
    }

    ir := iface.(*info.InfoResponse)

    wrapped := &InfoResponse{ir, p.Methods(), p.Type()}

    return wrapped, nil
}
