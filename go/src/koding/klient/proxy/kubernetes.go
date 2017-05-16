package proxy

import (
    "fmt"
    "net/http"
    "net/url"
    "regexp"
    "strings"
    "time"

    "koding/klient/registrar"

    "github.com/gorilla/websocket"
    "github.com/koding/kite"
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
    h := p.config.Host
    h = strings.Replace(h, "https://", "", -1)
    h = strings.Replace(h, "http://", "", -1)

    u := &url.URL{
        Scheme: "wss",
        Host:   h,
    }

    u.Path = fmt.Sprintf(
        "api/v1/namespaces/%s/pods/%s/exec",
        r.K8s.Namespace,
        r.K8s.Pod,
    )

    cmds := []string{}

    // Make cmds be an argv array to inject into the query
    // string for the websocket handshake.
    for _, v := range r.Common.Command {
        c := fmt.Sprintf("command=%s", url.QueryEscape(v))
        cmds = append(cmds, c)
    }

    u.RawQuery = fmt.Sprintf(
        "container=%s&%s&stdin=%t&stdout=%t&stderr=%t&tty=%t",
        r.K8s.Container,
        strings.Join(cmds, "&"),
        r.IO.Stdin,
        r.IO.Stdout,
        r.IO.Stderr,
        r.IO.Tty,
    )

    tlsConfig, err := rest.TLSConfigFor(p.config)
    if err != nil {
        return nil, err
    }

    d := &websocket.Dialer{
        TLSClientConfig: tlsConfig,
    }

    conn, _, err := d.Dial(u.String(), http.Header{
        "Authorization": []string{
            fmt.Sprintf("Bearer %s", p.config.BearerToken),
        },
    })
    if err != nil {
        fmt.Println("Failed to connect to K8s:", err)
        return nil, err
    }

    errChan := make(chan error)
    inChan := make(chan []byte)

    if r.IO.Stdin {
        go func() {
            defer close(inChan)

            for {
                select {
                    case d := <- inChan:
                        err := conn.WriteMessage(websocket.TextMessage, d)
                        if err != nil {
                            fmt.Println(err)
                            return
                        }
                }
            }

            fmt.Println("Exiting ingress proxier.")
        }()
    }

    // If requesting kite wants this klient to return output
    // and/or errors for the exec process.
    if r.IO.Stdout || r.IO.Stderr {
        go func() {
            for {
                err := conn.SetReadDeadline(time.Now().Add(time.Second * 3))
                if err != nil {
                    fmt.Println(err)
                    errChan <- err
                    return
                }

                _, m, err := conn.ReadMessage()
                if err != nil {
                    fmt.Println("Failed to read message from websocket:", err)
                    errChan <- err
                    return
                }

                if e := r.Output.Call(string(m)); e != nil {
                    fmt.Println("Failed to send message to client kite:", e)
                    return
                }

                fmt.Println("Looping output proxier.")
            }

            fmt.Println("Exiting output proxier.")
        }()
    }

    // Error handling
    go func() {
        defer conn.Close()
        defer close(errChan)

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

        err = conn.WriteMessage(
            websocket.CloseMessage,
            websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""),
        )
        if err != nil {
            fmt.Println("Failed to send close message to K8s for websocket.", err)
        }
    }()

    exec := &Exec{
        in:         inChan,

        Common:     r.Common,
        IO:         r.IO,
    }

    return exec, nil
}
