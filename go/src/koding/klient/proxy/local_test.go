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

func TestLocalType(t *testing.T) {
    p := proxy.NewLocal()

    if p.Type() != proxy.Local {
        t.Fatal("Local proxy didn't return the correct ProxyType.")
    }
}

func TestLocalMethods(t *testing.T) {
    p := proxy.NewLocal()

    _ = p.Methods()
}

func TestLocalList(t *testing.T) {
    p := proxy.NewLocal()

    mapping := map[string]kite.HandlerFunc{
        "proxy.list": p.List,
    }

    k, client := testutil.GetKites(mapping)
    defer k.Close()

    dnode, err := client.Tell("proxy.list", proxy.ListRequest{})
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
type TestExecRequest struct {
    output  chan    string
    done    chan    bool

    proxy.Common
    proxy.IO
}

func (r *TestExecRequest) Output(d *dnode.Partial) {
    data := d.MustSliceOfLength(1)[0].MustString()

    r.output <- data
}

func (r *TestExecRequest) Done(d *dnode.Partial) {
    data := d.MustSliceOfLength(1)[0].MustBool()

    r.done <- data
}

// TestLocalExec attempts to verify that a basic command can be exec'ed to the
// remote kite, and the output gets returned via the dnode.Function Output()
func TestLocalExec(t *testing.T) {
    p := proxy.NewLocal()

    mapping := map[string]kite.HandlerFunc{
        "proxy.exec": p.Exec,
    }

    k, client := testutil.GetKites(mapping)
    defer k.Close()

    expected := "foobar"

    r := &TestExecRequest{
        output:     make(chan string),
        done:       make(chan bool),

        Common:     proxy.Common{
            Session:    "TestLocalExec",
            Command:    []string{"/bin/echo", expected},
        },

        IO:         proxy.IO{
            Stdin:      false,
            Stdout:     true,
            Stderr:     true,
            Tty:        false,
        },
    }

    d, err := client.Tell("proxy.exec", r)
    if err != nil {
        t.Fatal(err)
    }

    var exec *proxy.ExecResponse

    if err = d.Unmarshal(&exec); err != nil {
        t.Fatal("Response should be of type proxy.ExecResponse.")
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

// TestLocalExecWithInput attempts to verify that we can sustain an Exec
// instance and proxy input to it's stdin pipe until it exits.
func TestLocalExecWithInput(t *testing.T) {
    p := proxy.NewLocal()

    mapping := map[string]kite.HandlerFunc{
        "proxy.exec": p.Exec,
    }

    k, client := testutil.GetKites(mapping)
    defer k.Close()

    r := &TestExecRequest{
        output:     make(chan string),
        done:       make(chan bool),

        Common:     proxy.Common{
            Session:    "TestLocalExec",
            Command:    []string{"/usr/bin/head", "-n", "1"},
        },

        IO:         proxy.IO{
            Stdin:      true,
            Stdout:     true,
            Stderr:     true,
            Tty:        false,
        },
    }

    d, err := client.Tell("proxy.exec", r)
    if err != nil {
        t.Fatal(err)
    }

    var exec *proxy.ExecResponse

    if err = d.Unmarshal(&exec); err != nil {
        t.Fatal("Response should be of type proxy.ExecResponse.")
    }

    expected := "foobizzle"

    if err := exec.Input.Call(expected + "\n"); err != nil {
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
