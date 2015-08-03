package logfetcher

import (
	"errors"
	"sync"

	"github.com/ActiveState/tail"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite/dnode"
)

type Request struct {
	Path  string
	Watch dnode.Function
}

var (
	tailedMu    sync.Mutex // protects the followings
	tailedFiles map[string]*tail.Tail
)

func Tail(r *kite.Request) (interface{}, error) {
	var params *Request
	if r.Args == nil {
		return nil, errors.New("arguments are not passed")
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	if !params.Watch.IsValid() {
		return nil, errors.New("watch argument is either not passed or is not a function")
	}

	t, err := tail.TailFile(params.Path, tail.Config{
		Follow: true,
	})
	if err != nil {
		return nil, err
	}

	go func() {
		for line := range t.Lines {
			params.Watch.Call(line.Text)
		}
	}()

	r.Client.OnDisconnect(func() {
		t.Stop()
	})

	return true, nil
}
