package proxy_test

import (
    "fmt"
    "testing"

    "koding/klient/proxy"
    "koding/klient/testutil"

    "github.com/koding/kite"
)

// These set of test cases act on a singleton instance of the manager
// type that oversees sessions depending on the type of proxy instance.

func TestGetSessions(t *testing.T) {
    p, err := proxy.NewKubernetes()
    if err != nil {
        t.Skip(skipMessage)
    }

    mapping := map[string]kite.HandlerFunc {
        "webterm.getSessions": p.GetSessions,
    }

    k, client := testutil.GetKites(mapping)
    defer k.Close()

    dnode, err := client.Tell("webterm.getSessions")
    if err != nil {
        t.Fatal(err)
    }

    var data []string

    if err = dnode.Unmarshal(&data); err != nil {
        t.Fatal("Response should be of type []string.")
    }

    fmt.Println(data)
}
