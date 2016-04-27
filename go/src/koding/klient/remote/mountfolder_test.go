package remote

import (
	"errors"
	"fmt"
	"koding/klient/remote/machine"
	"net/http/httptest"
	"testing"

	"github.com/koding/kite"
	. "github.com/smartystreets/goconvey/convey"
)

func TestCheckSizeOfRemotefolder(t *testing.T) {
	type ExecResponse struct {
		Stdout     string `json:"stdout"`
		Stderr     string `json:"stderr"`
		ExitStatus int    `json:"exitStatus"`
	}

	// The response that we're going to return on each exec call
	var expectedExecResponse ExecResponse
	var execCmd string

	s := kite.New("s", "0.0.0")
	s.Config.DisableAuthentication = true
	s.HandleFunc("exec", func(r *kite.Request) (interface{}, error) {
		var params struct {
			Command string
			Async   bool
		}
		if r.Args.One().Unmarshal(&params) != nil || params.Command == "" {
			return nil, errors.New("{command : [string]}")
		}

		execCmd = params.Command
		return expectedExecResponse, nil
	})
	ts := httptest.NewServer(s)

	c := kite.New("c", "0.0.0").NewClient(fmt.Sprintf("%s/kite", ts.URL))
	err := c.Dial()
	if err != nil {
		t.Fatal("Failed to connect to testing Kite", err)
	}

	// Set the expected response
	expectedExecResponse = ExecResponse{
		Stdout: "1200000000", // Sumulating response from du -sb /foo
	}

	res, err := checkSizeOfRemoteFolder(&machine.Machine{Transport: c}, "/foo")
	if err != nil {
		t.Error(err)
	}

	// Should send the proper command to the kite exec method
	if execCmd != "du -sb /foo" {
		t.Errorf("Unexpected command sent to kite. Expected '%s', got '%s'",
			"du -sb /foo", execCmd)
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

func TestGetSizeOfRemoteFolder(t *testing.T) {
	Convey("Given an empty path", t, func() {
		m := &machine.Machine{}
		path := ""

		Convey("It should return an error", func() {
			size, err := getSizeOfRemoteFolder(m, path)
			So(err, ShouldEqual, errGetSizeMissingRemotePath)
			So(size, ShouldEqual, 0)
		})
	})

	Convey("Given an nil machine", t, func() {
		var m *machine.Machine
		path := "/foo/bar"

		Convey("It should return an error", func() {
			size, err := getSizeOfRemoteFolder(m, path)
			So(err, ShouldEqual, errGetSizeMissingMachine)
			So(size, ShouldEqual, 0)
		})
	})
}
