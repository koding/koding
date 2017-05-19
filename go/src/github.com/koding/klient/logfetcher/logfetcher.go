package logfetcher

import (
	"crypto/rand"
	"encoding/base64"
	"errors"
	"sync"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/ActiveState/tail"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite/dnode"
)

type Request struct {
	Path  string
	Watch dnode.Function
}

type PathTail struct {
	Tail      *tail.Tail
	Listeners map[string]dnode.Function
}

var (
	tailedMu    sync.Mutex // protects the followings
	tailedFiles = make(map[string]*PathTail)
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

	// unique ID for each new connection
	clientId := randomStringLength(16)

	tailedMu.Lock()
	p, ok := tailedFiles[params.Path]
	tailedMu.Unlock()
	if !ok {
		t, err := tail.TailFile(params.Path, tail.Config{
			Follow:    true,
			MustExist: true,
		})
		if err != nil {
			return nil, err
		}

		p := &PathTail{
			Tail: t,
			Listeners: map[string]dnode.Function{
				clientId: params.Watch,
			},
		}

		tailedMu.Lock()
		tailedFiles[params.Path] = p
		tailedMu.Unlock()

		// start the tail only once for each path
		go func() {
			for line := range p.Tail.Lines {
				tailedMu.Lock()
				p, ok := tailedFiles[params.Path]
				tailedMu.Unlock()

				if !ok {
					continue
				}

				for _, listener := range p.Listeners {
					listener.Call(line.Text)
				}
			}

			// stop the tail all together if it somehow comes to here.
			tailedMu.Lock()
			p, ok := tailedFiles[params.Path]
			if !ok {
				tailedMu.Unlock()
				return
			}

			p.Tail.Stop()
			delete(tailedFiles, params.Path)
			tailedMu.Unlock()
		}()
	} else {
		// tailing is already started with a previous connection, just add this
		// new function so it's get notified too.
		p.Listeners[clientId] = params.Watch
	}

	r.Client.OnDisconnect(func() {
		tailedMu.Lock()
		p, ok := tailedFiles[params.Path]
		if ok {
			// delete the function for this connection
			delete(p.Listeners, clientId)

			// now check if there is any user left back. If we have removed
			// all users, we should also stop the watcher from watching the
			// path. So notify the watcher to stop watching the path and
			// also remove it from the callbacks map
			if len(p.Listeners) == 0 {
				p.Tail.Stop()
				delete(tailedFiles, params.Path)
			} else {
				tailedFiles[params.Path] = p // add back the decreased listener
			}
		}
		tailedMu.Unlock()
	})

	return true, nil
}

// randomStringLength is used to generate a session_id.
func randomStringLength(length int) string {
	size := (length * 6 / 8) + 1
	r := make([]byte, size)
	rand.Read(r)
	return base64.URLEncoding.EncodeToString(r)[:length]
}
