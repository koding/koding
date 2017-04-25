package proxy_test

import (
    "encoding/json"
    "testing"

    "koding/klient/proxy"
)

func TestLocalType(t *testing.T) {
    p := proxy.New(proxy.Local)

    if p.Type() != proxy.Local {
        t.Fatal("Local proxy didn't return the correct ProxyType.")
    }
}

func TestLocalList(t *testing.T) {
    p := proxy.New(proxy.Local)

    iface, err := p.List(nil)
    if err != nil {
        t.Fatal(err)
    }

    res, ok := iface.([]byte)
    if !ok {
        t.Fatal("Failed to assert type of response.")
    }

    var data proxy.ContainersResponse

    err = json.Unmarshal(res, &data)
    if err != nil {
        t.Fatal(err)
    }
}
