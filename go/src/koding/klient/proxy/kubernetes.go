package proxy

import (
    "encoding/json"
    "fmt"

    "github.com/koding/kite"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

var _ Proxy = (*KubernetesProxy)(nil)

type KubernetesProxy struct {
    client *kubernetes.Clientset
}

func (p *KubernetesProxy) Type() ProxyType {
    return Kubernetes
}

func (p *KubernetesProxy) Init() error {

    // If klient is running in Kubernetes proxy mode, then we expect
    // to exist inside the same pod that comprises the Stack. Thus
    // our environment should be configured just like any other member
    // of this pod, and we will pull necessary config accordingly.
    conf, err := rest.InClusterConfig()
	if err != nil {
		return err
	}

    // Initialize a client for our hosting Kubernetes API.
    p.client, err = kubernetes.NewForConfig(conf)
    if err != nil {
        return err
    }

    return nil
}

func (p *KubernetesProxy) List(r *kite.Request) (interface{}, error) {
    data := ContainersResponse{}

    // TODO: Query a K8s endpoint to actually get container data.
    pods, err := p.client.CoreV1().Pods("").List(metav1.ListOptions{})
    if err != nil {
        return nil, err
    }
    fmt.Println(pods)

    res, err := json.Marshal(data)

    if err != nil {
        return nil, err
    }

    return res, nil
}
