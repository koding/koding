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

// NOTE: Implementing a TestConnect is redundant with the test cases
// under kuberentes_test.go. The proxy.Connect kite.HandlerFunc that
// will return a similar object to the requesting kite that is currently
// returned from webterm.connect kite method. Similar meaning they have
// the same dnode.Function interfaces for sending and receiving as a
// terminal.Server object.

func TestKillSession(t *testing.T) {
    t.Skip("Not implemented.")
}

func TestKillSessions(t *testing.T) {
    t.Skip("Not implemented.")
}

func TestRenameSession(t *testing.T) {
    t.Skip("Not implemented.")
}

func TestCloseSessions(t *testing.T) {
    t.Skip("Not implemented.")
}
