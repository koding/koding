package logfetcher

import (
	"errors"
	"fmt"

	"github.com/ActiveState/tail"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
)

type Request struct {
	Path string
}

func Fetch(r *kite.Request) (interface{}, error) {
	var params *Request
	if r.Args == nil {
		return nil, errors.New("arguments are not passed")
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
		return nil, errors.New("{ path: [string] }")
	}

	t, err := tail.TailFile(params.Path, tail.Config{
		Follow: true,
	})
	if err != nil {
		return nil, err
	}

	for line := range t.Lines {
		fmt.Println(line.Text)
	}

	return nil, errors.New("not implemented yet")
}
