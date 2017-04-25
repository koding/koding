package proxy_test

import (
    "encoding/json"
    "testing"

    "koding/klient/proxy"
)

func TestKuberentesType(t *testing.T) {
    p := proxy.New(proxy.Kubernetes)

    if p.Type() != proxy.Kubernetes {
        t.Fatal("Kuberentes proxy didn't return the correct ProxyType.")
    }
}

func TestKubernetesList(t *testing.T) {
    p := proxy.New(proxy.Kubernetes)

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
