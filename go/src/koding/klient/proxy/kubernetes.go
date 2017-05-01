package proxy

import (
    "fmt"
    "regexp"

    "koding/klient/registrar"

    "github.com/koding/kite"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
    //"k8s.io/client-go/kubernetes/scheme"
    //"k8s.io/client-go/pkg/api/v1"
    "k8s.io/client-go/rest"
)

var _ Proxy = (*KubernetesProxy)(nil)

type KubernetesProxy struct {
    config *rest.Config
    client *kubernetes.Clientset
    rest   *rest.RESTClient
}

func (p *KubernetesProxy) Type() ProxyType {
    return Kubernetes
}

// TODO (acbodine): there should be more regexes in here to begin
// with, and this list could possibly go away over time.
var blacklist = []string{
    "fs.*",
}

func (p *KubernetesProxy) Methods() []string {
    data := []string{}

    for _, e := range registrar.Methods() {
        matched := false

        for _, v := range blacklist {
            if matched, _ = regexp.MatchString(v, e); matched {
                break
            }
        }

        if !matched {
            data = append(data, e)
        }
    }

    return data
}

func (p *KubernetesProxy) List(r *kite.Request) (interface{}, error) {
    var req ListRequest

	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

    res, err := p.list(&req)
    if err != nil {
        return nil, err
    }

    return res, nil
}

func (p *KubernetesProxy) list(r *ListRequest) (*ListResponse, error) {
    data := &ListResponse{}

    // Query a K8s endpoint to actually get container data.
    list, err := p.client.CoreV1().Pods(r.Pod).List(metav1.ListOptions{})
    if err != nil {
        return nil, err
    }

    for _, pod := range list.Items {
        spec := pod.Spec

        for _, c := range spec.Containers {
            data.Containers = append(data.Containers, c)
        }
    }

    return data, nil
}

func (p *KubernetesProxy) Exec(r *ExecRequest) error {

    // opts := &v1.PodExecOptions{
    //     Stdin: false,
    //     Stdout: true,
    //     Stderr: true,
    //     TTY: false,
    //     Container: "klient",
    //     Command: []string{"/bin/hostname"},
    // }

    // opts := metav1.ListOptions{}

    result, err := p.rest.Get().
            // TODO: Get namespace. Kubernetes default namespace is default?
            Namespace("default").
            Resource("pods").
            // TODO: Get pod name
            Name("koding").
            SubResource("exec").
            Param("Container", "klient").
            Param("Command", "/bin/hostname").
            // Body(opts).
            // VersionedParams(&opts, scheme.ParameterCodec).
            Do().
            Get()

    if err != nil {
        fmt.Println("Failed to do the resty stuff. ", err)
    }

    fmt.Println("result: ", result)

    return nil
}
