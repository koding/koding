package remote

import (
	"errors"
	"fmt"
	"koding/klient/remote/machine"
	"net/http/httptest"
	"testing"

	"github.com/koding/kite"
)

func TestCheckSizeOfRemotefolder(t *testing.T) {
	type ExecResponse struct {
		Stdout     string `json:"stdout"`
		Stderr     string `json:"stderr"`
		ExitStatus int    `json:"exitStatus"`
	}

	// The response that we're going to return on each exec call
	var (
		expectedPath  string = "/foo"
		requestedPath string
	)

	s := kite.New("s", "0.0.0")
	s.Config.DisableAuthentication = true
	s.HandleFunc("fs.getPathSize", func(r *kite.Request) (interface{}, error) {
		var params struct {
			Path string
		}
		if r.Args.One().Unmarshal(&params) != nil || params.Path == "" {
			return nil, errors.New("{path : [string]}")
		}

		requestedPath = params.Path
		return int64(1200000000), nil
	})
	ts := httptest.NewServer(s)

	c := kite.New("c", "0.0.0").NewClient(fmt.Sprintf("%s/kite", ts.URL))

	res, err := checkSizeOfRemoteFolder(&machine.Machine{Transport: c}, expectedPath)
	if err != nil {
		t.Error(err)
	}

	if expectedPath != requestedPath {
		t.Error("Expected path to be the same as requested. expected:%s, got:%s",
			expectedPath, requestedPath)
	}

	// Should return a string
	warning, ok := res.(string)
	if !ok {
		t.Errorf("checkSizeOfRemote did not return a string. Got '%#v'", res)
	}

	// Should return a warning if the filesize is too big
	if warning == "" {
		t.Errorf("checkSizeOfRemote should have returned a warning. Got an empty string instead.")
	}
}
