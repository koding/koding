package proxy_test

import (
    "fmt"
    "strings"
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

    dnode, err := client.Tell("proxy.exec", r)
    if err != nil {
        t.Fatal(err)
    }

    var exec *proxy.ExecResponse

    if err = dnode.Unmarshal(&exec); err != nil {
        t.Fatal("Response should be of type proxy.ExecResponse.")
    }

    returned := ""
    timeout := time.After(time.Second * 3)
    for !strings.Contains(returned, expected) {
        select {
            case o := <- r.output:
                returned += o
            case <- timeout:
                t.Fatal("Should return expected output, in a timely manner.")
        }
    }

    timeout = time.After(time.Millisecond * 100)
    for {
        select {
            case <- r.done:
                fmt.Println("Got the done callback")
                return
            case <- timeout:
                t.Fatal("Should notify client that remote exec is finished, in a timely manner.")
        }
    }
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

    dnode, err := client.Tell("proxy.exec", r)
    if err != nil {
        t.Fatal(err)
    }

    var exec *proxy.ExecResponse

    if err = dnode.Unmarshal(&exec); err != nil {
        t.Fatal("Response should be of type proxy.ExecResponse.")
    }

    expected := `foobar
    `

    if err := exec.Input.Call(expected); err != nil {
        t.Fatal(err)
    }

    timeout := time.After(time.Second * 3)

    returned := ""
    for !strings.Contains(returned, expected) {
        select {
            case o := <- r.output:
                returned += o
            case <- timeout:
                t.Fatal("Should return expected output, in a timely manner.")
        }
    }

    timeout = time.After(time.Millisecond * 100)
    for {
        select {
            case <- r.done:
                fmt.Println("Got the done callback")
                return
            case <- timeout:
                t.Fatal("Should notify client that remote exec is finished, in a timely manner.")
        }
    }
}

func TestKubernetesExecTerminal(t *testing.T) {
    t.Skip("Temporary")
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

    expected := "12345+1\n"
    if err := exec.Input.Call(fmt.Sprintf("print %s", expected)); err != nil {
        t.Fatal(err)
    }

    returned := ""
    for {
        select {
            case o := <- r.output:
                returned += o
            case <- r.done:
                if !strings.Contains(returned, expected) {
                    t.Fatal("Failed to return expected output: ", returned)
                }
                return
        }
    }
}
