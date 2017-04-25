package proxy_test

import (
    "testing"

    "koding/klient/proxy"
    "koding/klient/testutil"

    "github.com/koding/kite"
)

func TestLocalType(t *testing.T) {
    p := proxy.NewLocal()

    if p.Type() != proxy.Local {
        t.Fatal("Local proxy didn't return the correct ProxyType.")
    }
}

func TestLocalMethods(t *testing.T) {
    p := proxy.NewLocal()

    mapping := map[string]kite.HandlerFunc {
        "proxy.methods": p.Methods,
    }

    k, client := testutil.GetKites(mapping)
    defer k.Close()

	dnode, err := client.Tell("proxy.methods")
    if err != nil {
        t.Fatal(err)
    }

    var data proxy.MethodsResponse

    if err = dnode.Unmarshal(data); err != nil {
        t.Fatal("Response should be of type proxy.MethodsResponse.")
    }
}

func TestLocalList(t *testing.T) {
    p := proxy.NewLocal()

    mapping := map[string]kite.HandlerFunc {
        "proxy.list": p.List,
    }

    k, client := testutil.GetKites(mapping)
    defer k.Close()

    dnode, err := client.Tell("proxy.list")
    if err != nil {
        t.Fatal(err)
    }

    var data proxy.ContainersResponse

    if err = dnode.Unmarshal(data); err != nil {
        t.Fatal("Response should be of type proxy.ContainersResponse.")
    }
}
