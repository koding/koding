package logfetcher

import (
	"errors"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
)

type Request struct {
	Path string
}

func Fetch(r *kite.Request) (interface{}, error) {
	return nil, errors.New("not implemented yet")
}
