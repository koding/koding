package proxy

import (
    "os"

    kos "koding/klient/os"

    "github.com/koding/kite"
)

type Proxy interface {

    Type() ProxyType

    // NOTE: Probably temporary
    //
    // Init is a temporary method to allow runtime configuration
    // for an object that implements a Proxy.
    Init() error

    // List is a kite handler for the "proxy.list" method.
    //
    // Returns a *MachinesResponse representing machines that klient
    // is responsible for proxying commands to.
    List(*kite.Request) (interface{}, error)

}

func New(t ProxyType) Proxy {
    switch (t) {
        case Kubernetes:
            return &KubernetesProxy{
                client: nil,
            }
        default:
            return &LocalProxy{}
    }
}

var proxy Proxy

// TODO (acbodine): This is most likely temporary
//
// Singleton exposes a read-only instance of a Proxy to the rest of klient.
func Singleton() Proxy {
    if proxy == nil {
        t := Local

        if v, ok := kos.NewEnviron(os.Environ())["KLIENT_MACHINE_PROXY"]; ok {
            t = String2ProxyType[v]
        }

        proxy = New(t)

        // Allow proxy instance to setup any config it might have.
        _ = proxy.Init()
    }

    return proxy
}
