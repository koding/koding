package proxy_test

import (
    "strings"
    "testing"

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

    dnode, err := client.Tell("proxy.list")
    if err != nil {
        t.Fatal(err)
    }

    var data proxy.ListResponse

    if err = dnode.Unmarshal(data); err != nil {
        t.Fatal("Response should be of type proxy.ListResponse.")
    }
}

type TestExecRequest struct {
    output  chan    string
    done    chan    bool

    Session     string      `json:"session"`
    Command     []string    `json:"command"`
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

    expected := `foobar
    `

    r := &TestExecRequest{
        output:     make(chan string),
        done:       make(chan bool),

        Session:    "TestLocalExec",
        Command:    []string{"/bin/echo", strings.TrimSpace(expected)},
    }

    d, err := client.Tell("proxy.exec", r)
    if err != nil {
        t.Fatal(err)
    }

    var exec *proxy.ExecResponse

    if err = d.Unmarshal(&exec); err != nil {
        t.Fatal("Response should be of type proxy.ExecResponse.")
    }

    returned := ""
    for {
        select {
            case o := <- r.output:
                returned += o
            case <- r.done:
                if strings.Contains(returned, expected) {
                    t.Fatal("Failed to return expected output.")
                }
                return
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

        Session:    "TestLocalExec",
        Command:    []string{"/usr/bin/head", "-n", "1"},
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

    returned := ""
    for {
        select {
            case o := <- r.output:
                returned += o
            case <-r.done:
                if !strings.Contains(returned, expected) {
                    t.Fatal("Failed to return expected output.")
                }
                return
        }
    }
}
