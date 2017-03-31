package proxy

import (
    "github.com/koding/kite"
)

type LocalProxy struct {}

func (p *LocalProxy) List(r *kite.Request) (interface{}, error) {
    return "", nil
}
