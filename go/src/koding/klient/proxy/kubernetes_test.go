package proxy_test

import (
    "testing"

    "koding/klient/proxy"
    "koding/klient/testutil"

    "github.com/koding/kite"
)

var skipMessage = "Skipping test due to missing Kubernetes pod environment context."

func TestKuberentesType(t *testing.T) {
    p, err := proxy.NewKubernetes()
    if err != nil {
        t.Skip(skipMessage)
    }

    if p.Type() != proxy.Kubernetes {
        t.Fatal("Kuberentes proxy didn't return the correct ProxyType.")
    }
}

func TestKubernetesMethods(t *testing.T) {
    p, err := proxy.NewKubernetes()
    if err != nil {
        t.Skip(skipMessage)
    }

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

func TestKubernetesList(t *testing.T) {
    p, err := proxy.NewKubernetes()
    if err != nil {
        t.Skip(skipMessage)
    }

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
