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

// pumpIngress takes []byte messages from inChan, and sends them to the
// exec'd process via writer.
//
// TODO (acbodine): We might not need the time.Ticker anymore as we have
// an explicit handle to the Stream() function termination, and we close
// the inChan as a result of that. Thus we shouldn't ever block indefinitely
// here.
func pumpIngress(wg *sync.WaitGroup, inChan chan []byte, writer io.WriteCloser) {
    defer func () {
        wg.Done()
    }()

    ticker := time.NewTicker(readWait)

    defer ticker.Stop()

    for {
        select {
            case d, ok := <- inChan:
                if !ok {
                    // TODO (acbodine): If we want to allow detaching we
                    // shouldn't return here.

                    return
                }

                if _, err := writer.Write(d); err != nil {
                    fmt.Println("Failed to write bytes to connection:", err)
                    return
                }

                break
            case <- ticker.C:
                break
        }
    }
}

// pumpEgress reads from reader and sends back to the requesting kite via
// the provided dnode.Function callback said kite has specified.
func pumpEgress(wg *sync.WaitGroup, reader io.ReadCloser, callback dnode.Function) {
    defer func () {
        wg.Done()
    }()

    buf := make([]byte, 1024 * 4)

    for {
        // Read output chunks from the exec'd process until an error
        // occurs.
        num, err := reader.Read(buf)

        // If we read data, always send it back to the requesting kite.
        if num > 0 {
            if err := callback.Call(string(buf[:num])); err != nil {
                fmt.Println("Failed to send output to client kite:", err)
            }
        }

        if err == nil {
            continue
        }

        if err != io.EOF {
            fmt.Println("Failed to read from exec'd process:", err)
        }

        break
    }
}

// getUrl constructs a url.URL that is configured to establish a connection
// to the K8s API via remotecommand.StreamExecutor type.
func (p *KubernetesProxy) getUrl(r *ExecKubernetesRequest) (*url.URL, error) {
    u, err := url.Parse(p.config.Host)
    if err != nil {
        return nil, err
    }

    u.Path = fmt.Sprintf(
        "api/v1/namespaces/%s/pods/%s/exec",
        r.K8s.Namespace,
        r.K8s.Pod,
    )

    cmds := []string{}

    // Make cmds be an argv array to inject into the query
    // string for the connection to K8s API.
    for _, v := range r.Common.Command {
        c := fmt.Sprintf("command=%s", url.QueryEscape(v))
        cmds = append(cmds, c)
    }

    // Always pass true for stdin value to compose the query string
    // for the connection, without it K8s API won't pass back
    // output from exec'd process.
    u.RawQuery = fmt.Sprintf(
        "container=%s&%s&stdin=%t&stdout=%t&stderr=%t&tty=%t",
        r.K8s.Container,
        strings.Join(cmds, "&"),
        true,
        r.IO.Stdout,
        r.IO.Stderr,
        r.IO.Tty,
    )

    return u, nil
}

func (p *KubernetesProxy) exec(r *ExecKubernetesRequest) (*Exec, error) {
    u, err := p.getUrl(r)
    if err != nil {
        return nil, err
    }

    // The remotecommand.StreamExecutor that we get back here knows
    // how to talk to K8s API.
    executor, err := remotecommand.NewExecutor(p.config, "POST", u)
    if err != nil {
        return nil, err
    }

    // NOTE: If we pass a nil io.ReadCloser to the StreamExecutor
    // below, then no output gets sent back on our out pipes. So
    // always pass valid io.ReadCloser to the StreamExecutor,
    // regardless of r.IO.Stdin value.
    var outReader, outWriter = io.Pipe()
    var inReader, inWriter = io.Pipe()
    var inChan = make(chan []byte)
    var wg sync.WaitGroup

    opts := remotecommand.StreamOptions{
        SupportedProtocols: kuberc.SupportedStreamingProtocols,
        Stdin:              inReader,
        Stdout:             outWriter,
        Stderr:             outWriter,
        Tty:                r.IO.Tty,
    }

    // If requesting kite wants to send input to exec'd
    // process, kickoff pumpIngress routine.
    //
    // NOTE: Remember to pass pointer to sync.WaitGroup here,
    // otherwise wg.Done() doesn't work because its a copy.
    if r.IO.Stdin {
        wg.Add(1)
        go pumpIngress(&wg, inChan, inWriter)
    }

    // If requesting kite wants output from the exec'd
    // process, kickoff pumpEgress routine.
    //
    // NOTE: Remember to pass pointer to sync.WaitGroup here,
    // otherwise wg.Done() doesn't work because its a copy.
    if r.IO.Stdout || r.IO.Stderr {
        wg.Add(1)
        go pumpEgress(&wg, outReader, r.Output)
    }

    // This goroutine handles cleanup for our proxy goroutines
    // started above.
    go func () {

        // This will block until a client closes the connection, or
        // the server disconnects (i.e. exec'd process has finished).
        if err := executor.Stream(opts); err != nil {
            fmt.Println("Error while streaming:", err)

            // NOTE: When err is nil, there was no unexpected errors
            // while streaming the connection. An err here is not good.

            // TODO (acbodine): What to do here?
        }

        // Notify egress proxy routine that streaming has finished
        // and it should exit.
        outWriter.Close()

        // If an ingress proxy routine was kicked off, we need
        // to close the channel it is consuming from, allowing
        // said routine to exit.
        if r.IO.Stdin {
            close(inChan)
        }
        inReader.Close()

        // Guarantee the goroutines we started to proxy io have
        // exited, before notifying requesting kite.
        wg.Wait()

        // Notify requesting kite that the exec'd process, and all
        // our local routines are finished.
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
