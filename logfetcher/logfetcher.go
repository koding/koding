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
	tailedFiles = make(map[string]*tail.Tail)
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
		return nil, errors.New("watch argument is either not passed or it's not a function")
	}

	var err error

	tailedMu.Lock()
	t, ok := tailedFiles[params.Path]
	tailedMu.Unlock()
	if !ok {
		t, err = tail.TailFile(params.Path, tail.Config{
			Follow: true,
		})
		if err != nil {
			return nil, err
		}

		tailedMu.Lock()
		tailedFiles[params.Path] = t
		tailedMu.Unlock()
	}

	stopTail := func() {
		tailedMu.Lock()
		t.Stop()
		delete(tailedFiles, params.Path)
		tailedMu.Unlock()
	}

	go func() {
		for line := range t.Lines {
			params.Watch.Call(line.Text)
		}
		stopTail() // if it stops somehow, just cleanup anything else
	}()

	r.Client.OnDisconnect(stopTail)

	return true, nil
}
