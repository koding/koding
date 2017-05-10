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

func (p *KubernetesProxy) WebsocketConfig(specifier string) (*websocket.Config, error) {
    target := p.config.Host

    target = strings.Replace(target, "https://", "wss://", -1)
    target = strings.Replace(target, "http://", "ws://", -1)

    action := fmt.Sprintf("%s/%s", target, specifier)
    action = strings.Replace(action, "//api", "/api", -1)

    c, err := websocket.NewConfig(action, target)
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

    return c, nil
}

func (p *KubernetesProxy) exec(r *ExecKubernetesRequest) (*Exec, error) {

    s := fmt.Sprintf(
        "api/v1/namespaces/%s/pods/%s/exec",
        r.K8s.Namespace,
        r.K8s.Pod,
    )

    sWithQuery := fmt.Sprintf(
        "%s?container=%s&command=%s&stdin=%t&stdout=%t&stderr=%t&tty=%t",
        s,
        r.K8s.Container,
        url.QueryEscape(strings.Join(r.Common.Command, "+")),
        r.IO.Stdin,
        r.IO.Stdout,
        r.IO.Stderr,
        r.IO.Tty,
    )

    config, err := p.WebsocketConfig(sWithQuery)
    if err != nil {
        return nil, err
    }

    conn, err := websocket.DialConfig(config)
    if err != nil {
        return nil, err
    }

    inReader, inWriter := io.Pipe()

    errChan := make(chan error)

    go func() {
        if !r.IO.Stdin {
            return
        }

        // An error here, means that something has happened
        // on the requesting kite's side. Maybe they tried
        // to detach? Should we allow re-connecting?
        io.Copy(conn, inReader)
    }()

    // Proxy all output from the websocket connection to
    // the Output dnode.Function provided by requesting kite.
    go func() {
        if !r.IO.Stdout && !r.IO.Stderr {
            return
        }

        util.PassTo(r.Output, conn, errChan)
    }()

    // Error handling
    go func() {
        e := <- errChan

        // TODO (acbodine): Verify we are catching an EOF here to exit cleanly.
        fmt.Println("Error handling caught ", e)

        // TODO (acbodine): Until we find a better way to detect if
        // the remote exec process has finished/errored, we will
        // treat errors received from the websocket Reader as
        // indicating the remote exec process is done.
        if err := r.Done.Call(true); err != nil {
            fmt.Println(err)
        }

        conn.Close()
        inReader.Close()

        close(errChan)
    }()

    exec := &Exec{
        in:         inWriter,

        Common:     r.Common,
        IO:         r.IO,
    }

    return exec, nil
}
