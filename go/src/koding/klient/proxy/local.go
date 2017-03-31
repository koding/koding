package proxy

import (
    "koding/klient/fs"

    "github.com/koding/kite"
)

type LocalProxy struct {}

func (p *LocalProxy) ReadFile(r *kite.Request) (interface{}, error) {
    return fs.ReadFile(r)
}
