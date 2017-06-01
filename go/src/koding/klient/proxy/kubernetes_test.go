package proxy_test

import (
    "fmt"
    "strings"
    "sync"
    "testing"
    "time"

    "koding/klient/proxy"
    "koding/klient/testutil"

    "github.com/koding/kite"
    "github.com/koding/kite/dnode"
)

var skipMessage = "Skipping test due to missing Kubernetes pod environment context."

func TestKubernetesType(t *testing.T) {
    p, err := proxy.NewKubernetes()
    if err != nil {
        t.Skip(skipMessage)
    }

    if p.Type() != proxy.Kubernetes {
        t.Fatal("Kubernetes proxy didn't return the correct ProxyType.")
    }
}

func TestKubernetesMethods(t *testing.T) {
    p, err := proxy.NewKubernetes()
    if err != nil {
        t.Skip(skipMessage)
    }

    _ = p.Methods()

    // TODO (acbodine): Validate that a Kubernetes proxy excludes fs.* and any
    // other kite methods necessary at this time.
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

    dnode, err := client.Tell("proxy.list", proxy.ListKubernetesRequest{
        Pod: "",
    })
    if err != nil {
        t.Fatal(err)
    }

    var data *proxy.ListResponse

    if err = dnode.Unmarshal(&data); err != nil {
        t.Fatal("Response should be of type proxy.ListResponse.")
    }
}

// Mock a similar request to the ExecKubernetesRequest so we can
// control what happens with the callbacks (Output, Done)
type TestExecKubernetesRequest struct {
    output  chan    string
    done    chan    bool

    proxy.Common
    proxy.IO
    proxy.K8s
}

func (r *TestExecKubernetesRequest) Output(d *dnode.Partial) {
    data := d.MustSliceOfLength(1)[0].MustString()

    r.output <- data
}

func (r *TestExecKubernetesRequest) Done(d *dnode.Partial) {
    data := d.MustSliceOfLength(1)[0].MustBool()

    r.done <- data
}

func TestKubernetesExec(t *testing.T) {
    p, err := proxy.NewKubernetes()
    if err != nil {
        t.Skip(skipMessage)
    }

    mapping := map[string]kite.HandlerFunc{
        "proxy.exec": p.Exec,
    }

    k, client := testutil.GetKites(mapping)
    defer k.Close()

    expected := "foobar"

    r := &TestExecKubernetesRequest{
        output:     make(chan string),
        done:       make(chan bool),

        Common: proxy.Common{
            Session:        "TestKubernetesExec",
            Command:        []string{"/bin/echo", expected},
        },

        IO: proxy.IO{
            Stdin:          false,
            Stdout:         true,
            Stderr:         true,
            Tty:            false,
        },

        K8s: proxy.K8s{
            Namespace:      "default",
            Pod:            "koding",
            Container:      "klient",
        },
    }

    var wg sync.WaitGroup

    returned := ""
    wg.Add(1)
    go func () {
        defer wg.Done()

        timeout := time.After(time.Second * 3)

        for !strings.Contains(returned, expected) {
            select {
                case o := <- r.output:
                    returned += o
                case <- timeout:
                    t.Fatal("Should return expected output, in a timely manner.")
            }
        }
    }()

    dnode, err := client.Tell("proxy.exec", r)
    if err != nil {
        t.Fatal(err)
    }

    var exec *proxy.ExecResponse

    if err = dnode.Unmarshal(&exec); err != nil {
        t.Fatal("Response should be of type proxy.ExecResponse.")
    }

    wg.Add(1)
    go func() {
        defer wg.Done()

        timeout := time.After(time.Second * 3)
        for {
            select {
                case <- r.done:
                    return
                case <- timeout:
                    t.Fatal("Should notify client that remote exec is finished, in a timely manner.")
            }
        }
    }()

    wg.Wait()
}

func TestKubernetesExecWithInput(t *testing.T) {
    p, err := proxy.NewKubernetes()
    if err != nil {
        t.Skip(skipMessage)
    }

    mapping := map[string]kite.HandlerFunc{
        "proxy.exec": p.Exec,
    }

    k, client := testutil.GetKites(mapping)
    defer k.Close()

    r := &TestExecKubernetesRequest{
        output:     make(chan string),
        done:       make(chan bool),

        Common: proxy.Common{
            Session:        "TestKubernetesExecWithInput",
            Command:        []string{"/usr/bin/head", "-n", "1"},
        },

        IO: proxy.IO{
            Stdin:          true,
            Stdout:         true,
            Stderr:         true,
            Tty:            false,
        },

        K8s: proxy.K8s{
            Namespace:      "default",
            Pod:            "koding",
            Container:      "klient",
        },
    }

    var wg sync.WaitGroup

    expected := `foobar
    `

    wg.Add(1)
    go func() {
        defer wg.Done()

        timeout := time.After(time.Second * 5)

        returned := ""
        for strings.Compare(strings.TrimSpace(returned), strings.TrimSpace(expected)) != 0 {
            select {
                case o := <- r.output:
                    returned += o
                case <- timeout:
                    t.Fatal("Should return expected output, in a timely manner.")
            }

            // TODO (acbodine): Make note of why this is necessary.
            returned = strings.Trim(returned, "\x01")
        }
    }()

    dnode, err := client.Tell("proxy.exec", r)
    if err != nil {
        t.Fatal(err)
    }

    var exec *proxy.ExecResponse

    if err = dnode.Unmarshal(&exec); err != nil {
        t.Fatal("Response should be of type proxy.ExecResponse.")
    }

    if err := exec.Input.Call(expected); err != nil {
        t.Fatal(err)
    }

    wg.Add(1)
    go func() {
        defer wg.Done()

        timeout := time.After(time.Second * 5)

        for {
            select {
                case <- r.done:
                    return
                case <- timeout:
                    t.Fatal("Should notify client that remote exec is finished, in a timely manner.")
            }
        }
    }()

    wg.Wait()
}

func TestKubernetesExecTerminal(t *testing.T) {
    p, err := proxy.NewKubernetes()
    if err != nil {
        t.Skip(skipMessage)
    }

    mapping := map[string]kite.HandlerFunc{
        "proxy.exec": p.Exec,
    }

    k, client := testutil.GetKites(mapping)
    defer k.Close()

    r := &TestExecKubernetesRequest{
        output:     make(chan string),
        done:       make(chan bool),

        Common: proxy.Common{
            Session:        "TestKubernetesExecTerminal",
            Command:        []string{"/bin/bash"},
        },

        IO: proxy.IO{
            Stdin:          true,
            Stdout:         true,
            Stderr:         true,
            Tty:            true,
        },

        K8s: proxy.K8s{
            Namespace:      "default",
            Pod:            "koding",
            Container:      "klient",
        },
    }

    var wg sync.WaitGroup

    expected := "12345+1\n"

    wg.Add(1)
    go func () {
        defer wg.Done()

        timeout := time.After(time.Second * 5)

        returned := ""
        for strings.Compare(strings.TrimSpace(returned), strings.TrimSpace(expected)) != 0 {
            select {
            case o := <- r.output:
                returned += o
            case <- timeout:
                t.Fatal("Should return expected output, in a timely manner.")
            }

            // TODO (acbodine): Make note of why this is necessary.
            returned = strings.Trim(returned, "\x01")
        }
    }()

    dnode, err := client.Tell("proxy.exec", r)
    if err != nil {
        t.Fatal(err)
    }

    var exec *proxy.ExecResponse

    if err = dnode.Unmarshal(&exec); err != nil {
        t.Fatal("Response should be of type proxy.ExecResponse.")
    }

    if err := exec.Input.Call("python"); err != nil {
        t.Fatal(err)
    }

    if err := exec.Input.Call(fmt.Sprintf("print %s", expected)); err != nil {
        t.Fatal(err)
    }

    wg.Add(1)
    go func () {
        defer wg.Done()

        timeout := time.After(time.Second * 5)

        for {
            select {
            case <- r.done:
                return
            case <- timeout:
                t.Fatal("Should notify client that remote exec is finished, in a timely manner.")
            }
        }
    }()

    wg.Wait()
}
