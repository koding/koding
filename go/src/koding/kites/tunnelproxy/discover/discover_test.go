package discover_test

import (
	"encoding/json"
	"os"
	"testing"

	"koding/kites/tunnelproxy/discover"
)

func args() []string {
	var arg string
	var args = os.Args

	for len(args) > 0 {
		arg, args = args[0], args[1:]
		if arg == "--" {
			return args
		}
	}

	return nil
}

func TestDiscover(t *testing.T) {
	args := args()
	if len(args) != 2 {
		t.Skip("usage: go test -run TestDiscover -- addr service")
	}

	e, err := discover.NewClient().Discover(args[0], args[1])
	if err != nil {
		t.Fatalf("Discover(%s, %s)=%s", args[0], args[1], err)
	}

	p, err := json.MarshalIndent(e, "", "\t")
	if err != nil {
		t.Fatal(err)
	}

	os.Stderr.Write(p)
}
