package proxy

import (
    "fmt"
    "io"
    "net/http"
    "net/url"
    "regexp"
    "strings"

    "koding/klient/registrar"
    "koding/klient/util"

    "github.com/koding/kite"
    "golang.org/x/net/websocket"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
    "k8s.io/client-go/rest"
)

var _ Proxy = (*KubernetesProxy)(nil)

type KubernetesProxy struct {
    config *rest.Config
    client *kubernetes.Clientset
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
    var req *ListKubernetesRequest

	if err := r.Args.One().Unmarshal(&req); err != nil {
		return nil, err
	}

    res, err := p.list(req)
    if err != nil {
        return nil, err
    }

    return res, nil
}

func (p *KubernetesProxy) list(r *ListKubernetesRequest) (*ListResponse, error) {
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

func (p *KubernetesProxy) Exec(r *kite.Request) (interface{}, error) {
    var req *ExecKubernetesRequest

    if err := r.Args.One().Unmarshal(&req); err != nil {
        return nil, err
    }

    res, err := p.exec(req)
    if err != nil {
        return nil, err
    }

    return res, nil
}

func (p *KubernetesProxy) exec(r *ExecKubernetesRequest) (*Exec, error) {

    // TODO (acbodine): Setup call to K8s API and hookup to
    // client via dnode.Functions

    origin := ""
    if strings.Contains(p.config.Host, "https://") {
        origin = strings.Replace(p.config.Host, "https://", "wss://", -1)
    } else {
        origin = strings.Replace(p.config.Host, "http://", "ws://", -1)
    }

    wsUrl := fmt.Sprintf(
        "%s/api/v1/namespaces/%s/pods/%s/exec",
        origin,
        r.Namespace,
        r.Pod,
    )

    wsUrl = strings.Replace(wsUrl, "//api", "/api", -1)

    wsUrlWithQuery := fmt.Sprintf(
        "%s?container=%s&command=%s",
        wsUrl,
        r.Container,
        url.QueryEscape(strings.Join(r.Command, "+")),
    )

    c, err := websocket.NewConfig(wsUrlWithQuery, origin)
    if err != nil {
        return nil, err
    }

    tlsConfig, err := rest.TLSConfigFor(p.config)
    if err != nil {
        return nil, err
    }
    c.TlsConfig = tlsConfig

    c.Header = http.Header{
        "Authorization": []string{fmt.Sprintf("Bearer %s", p.config.BearerToken)},
    }

    conn, err := websocket.DialConfig(c)
    if err != nil {
        return nil, err
    }

    inReader, inWriter := io.Pipe()

    errChan := make(chan error)

    go func() {
        // An error here, means that something has happened
        // on the requesting kite's side. Maybe they tried
        // to detach? Should we allow re-connecting?
        io.Copy(conn, inReader)
    }()

    // Proxy all output from the websocket connection to
    // the Output dnode.Function provided by requesting kite.
    go func() {
        util.PassTo(r.Output, conn, errChan)
    }()

    // Error handling
    go func() {
        // defer close(errChan)

        for {
            select {
                case e := <- errChan:
                    fmt.Println("Error handling caught ", e)

                    // TODO (acbodine): Until we find a better way to detect if
                    // the remote exec process has finished/errored, we will
                    // treat errors received from the websocket Reader as
                    // indicating the remote exec process is done.
                    _ = r.Done.Call(true)

                    return
            }
        }
    }()

    exec := &Exec{
        in:         inWriter,

        Session:    r.Session,
        Command:    r.Command,
    }

    return exec, nil
}
