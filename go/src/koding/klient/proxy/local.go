package proxy

import (
    "encoding/json"

    "github.com/koding/kite"
)

var _ Proxy = (*LocalProxy)(nil)

type LocalProxy struct {}

func (p *LocalProxy) Init() error {
    return nil
}

func (p *LocalProxy) Type() ProxyType {
    return Local
}

func (p *LocalProxy) List(r *kite.Request) (interface{}, error) {
    data := ContainersResponse{}

    res, err := json.Marshal(data)

    if err != nil {
        return nil, err
    }

    return res, nil
}
