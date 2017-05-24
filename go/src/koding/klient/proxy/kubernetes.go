package proxy

import (
    "fmt"
    "io"
    "net/url"
    "regexp"
    "strings"
    "sync"
    "time"

    "koding/klient/registrar"

    "github.com/koding/kite"
    "github.com/koding/kite/dnode"


    kubev1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    kuberc "k8s.io/apimachinery/pkg/util/remotecommand"
	"k8s.io/client-go/kubernetes"
    "k8s.io/client-go/rest"
    "k8s.io/client-go/tools/remotecommand"
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
    list, err := p.client.CoreV1().Pods(r.Pod).List(kubev1.ListOptions{})
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

const (
    writeWait = time.Millisecond * 500
    readWait = time.Second * 1
)

func pumpIngress(inChan chan []byte, writer io.WriteCloser) {
    defer close(inChan)
    defer writer.Close()
    defer fmt.Println("Exiting ingress proxier.")

    ticker := time.NewTicker(readWait)

    defer ticker.Stop()

    for {
        select {
            case d, ok := <- inChan:
                if !ok {
                    fmt.Println("inChan was closed by requesting kite.")

                    // TODO (acbodine): !ok means inChan was closed
                    // by the requesting kite client. If we want to
                    // allow detaching we shouldn't return here.

                    return
                }

                if num, err := writer.Write(d); err != nil {
                    fmt.Println("Failed to write bytes to connection:", err)
                    return
                } else {
                    fmt.Println("Wrote", num, "bytes to connection.")
                }

                break
            case <- ticker.C:
                break
        }
        fmt.Println("Looping on ingress proxier.")
    }
}

func pumpEgress(wg sync.WaitGroup, reader io.ReadCloser, callback dnode.Function) {
    defer reader.Close()
    defer wg.Done()
    defer fmt.Println("Exiting egress proxier.")

    buf := make([]byte, 1024 * 4)

    for {
        // Read output chunks from the exec'd process until an error
        // occurs.
        num, err := reader.Read(buf)

        if num > 0 {
            if err := callback.Call(string(buf[:num])); err != nil {
                fmt.Println("Failed to send output to client kite:", err)
            }
        }

        if err != nil {
            fmt.Println("Failed to read from exec'd process:", err)
            break
        }

        fmt.Println("Looping on egress proxier.")
    }
}

func (p *KubernetesProxy) exec(r *ExecKubernetesRequest) (*Exec, error) {
    var inReader, inWriter = io.Pipe()
    var inChan = make(chan []byte)

    if !r.IO.Stdin {
        inReader, inWriter = nil, nil
    }

    var outReader, outWriter = io.Pipe()

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

    fmt.Println("Connecting to:", u.String())

    executor, err := remotecommand.NewExecutor(p.config, "POST", u)
    if err != nil {
        return nil, err
    }

    opts := remotecommand.StreamOptions{
        SupportedProtocols: kuberc.SupportedStreamingProtocols,
        Stdin:              inReader,
        Stdout:             outWriter,
        Stderr:             outWriter,
        Tty:                r.IO.Tty,
    }

    if err := executor.Stream(opts); err != nil {
        return nil, err
    }

    var wg sync.WaitGroup

    // If requesting kite wants to send input to exec'd
    // process, kickoff pumpIngress routine.
    if r.IO.Stdin {
        wg.Add(1)
        go pumpIngress(inChan, inWriter)
    }

    // If requesting kite wants output from the exec'd
    // process, kickoff pumpEgress routine.
    if r.IO.Stdout || r.IO.Stderr {
        wg.Add(1)
        go pumpEgress(wg, outReader, r.Output)
    }

    go func () {
        defer fmt.Println("Exiting done routine.")

        wg.Wait()
        fmt.Println("Proxier routines finished.")

        if err := r.Done.Call(true); err != nil {
            fmt.Println(err)
        }
    }()

    exec := &Exec{
        in:         inChan,

        Common:     r.Common,
        IO:         r.IO,
    }

    return exec, nil
}
