package proxy_test

import (
    "strings"
    "testing"

    "koding/klient/proxy"
    "koding/klient/testutil"

    "github.com/koding/kite"
    "github.com/koding/kite/dnode"
)

var skipMessage = "Skipping test due to missing Kubernetes pod environment context."

func TestKuberentesType(t *testing.T) {
    p, err := proxy.NewKubernetes()
    if err != nil {
        t.Skip(skipMessage)
    }

    if p.Type() != proxy.Kubernetes {
        t.Fatal("Kuberentes proxy didn't return the correct ProxyType.")
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

type TestExecKubernetesRequest struct {
    output  chan    string
    done    chan    bool

    Session     string      `json:"session"`
    Command     []string    `json:"command"`
    Namespace   string      `json:"namespace"`
    Pod         string      `json:"pod"`
    Container   string      `json:"container"`
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

    expected := `foobar
    `

    r := &TestExecKubernetesRequest{
        output:     make(chan string),
        done:       make(chan bool),

        Session:        "TestKubernetesExec",
        Command:        []string{"/bin/echo", strings.TrimSpace(expected)},

        Namespace:      "default",
        Pod:            "koding",
        Container:      "klient",
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
