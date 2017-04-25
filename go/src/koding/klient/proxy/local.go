package proxy

import (
    "koding/klient/registrar"

    "github.com/koding/kite"
)

var _ Proxy = (*LocalProxy)(nil)

type LocalProxy struct {}

func (p *LocalProxy) Type() ProxyType {
    return Local
}

func (p *LocalProxy) Methods(r *kite.Request) (interface{}, error) {
    data := &MethodsResponse{}

    for _, e := range registrar.Methods() {
        data.Methods = append(data.Methods, e)
    }

    return data, nil
}

func (p *LocalProxy) List(r *kite.Request) (interface{}, error) {
    data := ContainersResponse{}

    return data, nil
}
