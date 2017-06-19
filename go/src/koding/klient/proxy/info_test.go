package proxy_test

import (
	"testing"

	"koding/klient/info"
	"koding/klient/proxy"
    "koding/klient/testutil"

    "github.com/koding/kite"
)

// TestInfo aims to validate the request/response transaction associated
// with the 'klient.info' kite call between a kite and a klient kite.
func TestInfo(t *testing.T) {
    p, err := proxy.NewKubernetes()
    if err != nil {
        t.Skip(skipMessage)
    }

    mapping := map[string]kite.HandlerFunc {
        "klient.info": p.Info,
    }

    k, client := testutil.GetKites(mapping)
    defer k.Close()

	r := &info.InfoRequest{Lookup: false}
    dnode, err := client.Tell("klient.info", r)
    if err != nil {
        t.Fatal(err)
    }

    var data *proxy.InfoResponse

    if err = dnode.Unmarshal(data); err != nil {
        t.Fatal("Response should be of type proxy.InfoResponse.")
    }
}
