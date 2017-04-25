package info_test

import (
	"testing"

    "koding/klient/info"
    "koding/klient/testutil"

    "github.com/koding/kite"
)

// TestInfo aims to validate the request/response transaction associated
// with the 'klient.info' kite call between a kite and a klient kite.
func TestInfo(t *testing.T) {
    mapping := map[string]kite.HandlerFunc {
        "klient.info": info.Info,
    }

    k, client := testutil.GetKites(mapping)
    defer k.Close()

	dnode, err := client.Tell("klient.info")
    if err != nil {
        t.Fatal(err)
    }

    var data info.InfoResponse

    if err = dnode.Unmarshal(data); err != nil {
        t.Fatal("Response should be of type info.InfoResponse.")
    }
}
