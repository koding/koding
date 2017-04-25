package proxy

import (
    "fmt"

    "koding/klient/registrar"

    "github.com/koding/kite"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
)

var _ Proxy = (*KubernetesProxy)(nil)

type KubernetesProxy struct {
    client *kubernetes.Clientset
}

func (p *KubernetesProxy) Type() ProxyType {
    return Kubernetes
}

func (p *KubernetesProxy) Methods(r *kite.Request) (interface{}, error) {
    data := &MethodsResponse{}

    for _, e := range registrar.Methods() {
        data.Methods = append(data.Methods, e)
    }

    // TODO (acbodine): Strip out methods that we can't support atm.

    return data, nil
}

func (p *KubernetesProxy) List(r *kite.Request) (interface{}, error) {
    data := ContainersResponse{}

    // Query a K8s endpoint to actually get container data.
    list, err := p.client.CoreV1().Pods("").List(metav1.ListOptions{})
    if err != nil {
        return nil, err
    }

    for _, e := range list.Items {
        // TODO (acbodine): Make this pull the actual hostname.
        fmt.Println(e)
        data.Containers = append(data.Containers, Container{
            Hostname: "localhost",
        })
    }

    return data, nil
}
