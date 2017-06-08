package proxy_test

import (
    "testing"
    "os"

    kos "koding/klient/os"
    "koding/klient/proxy"
)

// TestFactory attempts to validate the behavior of the convenience method
// proxy.Factory.
//
// proxy.Factory should return an appropriate proxy.Proxy instance based on
// the current environment that tests/klient are/is running in.
func TestFactory(t *testing.T) {
    p := proxy.Factory()

    if _, kubeEnv := kos.NewEnviron(os.Environ())["KUBERNETES_SERVICE_HOST"]; kubeEnv {

        // If there are environment variables that look even a little like
        // the variables that Kubernetes sets up for pod members, then we
        // expect to receive a proxy.Kubernetes instance.
        if _, ok := p.(*proxy.KubernetesProxy); !ok {
            t.Fatal("Should return a Kubernetes proxy.")
        }
    }
}
