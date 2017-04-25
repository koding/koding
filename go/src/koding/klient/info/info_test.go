package info_test

import (
    "fmt"
	"testing"

    "koding/klient/info"

    "github.com/koding/kite"
)

// TestInfo aims to validate the request/response transaction associated
// with the 'klient.info' kite call between a kite and a klient kite.
func TestInfo(t *testing.T) {
    port := 56790

    k := kite.New("tester", "0.0.1")
    k.HandleFunc("klient.info", info.Info).DisableAuthentication()
    k.Config.Port = port
    defer k.Close()
    go k.Run()
    <-k.ServerReadyNotify()

    url := fmt.Sprintf("http://localhost:%d/kite", port)
    client := k.NewClient(url)
	client.Dial()

	dnode, err := client.Tell("klient.info")
    if err != nil {
        t.Fatal(err)
    }

    m, err := dnode.Map()
    if err != nil {
        t.Fatal(err)
    }

    if m["machineproxy"] == nil {
        t.Fatal("klient.info response should contain 'machineproxy' property.")
    }

	// fmt.Printf("klient.info: provider:%s arch:%s os:%s proxy:%s\n",
    //     m["providerName"].MustString(),
    //     m["arch"].MustString(),
    //     m["os"].MustString(),
    //     m["machineproxy"].MustString(),
    // )
}
