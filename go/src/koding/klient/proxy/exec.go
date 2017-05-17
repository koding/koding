package proxy

import (
    "fmt"
    "os/exec"

    "github.com/koding/kite/dnode"
    //"github.com/rogpeppe/go-charset/charset"
    // _ "github.com/rogpeppe/go-charset/data"
)

type Common struct {
    Session     string          `json:"session"`
    Command     []string        `json:"command"`
}

type IO struct {
    Stdin       bool            `json:"stdin"`
    Stdout      bool            `json:"stdout"`
    Stderr      bool            `json:"stderr"`
    Tty         bool            `json:"tty"`
}

type Remote struct {
    Output      dnode.Function
    Done        dnode.Function
}

type K8s struct {
    Namespace   string
    Pod         string
    Container   string
}

// ExecRequest is a helper type to verify the
// request to the "proxy.exec" kite endpoint.
type ExecRequest struct {
    Common
    IO
    Remote
}

// ExecKubernetesRequest is a helper type to verify requests to the
// "proxy.exec" kite endpoint, when we are proxying to K8s containers.
type ExecKubernetesRequest struct {
    ExecRequest
    K8s
}

// Exec is the server side representation of a command
// that was exec'ed by this client into some context
// depending on what the current proxy type is.
type Exec struct {
    Common
    IO

    cmd         *exec.Cmd
    in          chan []byte
}

// ExecResponse is a helper type for clients to Unmarshal
// the response from the "proxy.exec" kite method. It is
// the client-side representation of the Exec type.
type ExecResponse struct {
    Common

    Input           dnode.Function
    ControlSequence dnode.Function
    Kill            dnode.Function
}

// Input is a dnode.Function that is exposed to the client, allowing
// them to send data to an Exec instance.
func (r *Exec) Input(d *dnode.Partial) {
    data := d.MustSliceOfLength(1)[0].MustString()

    fmt.Println("Proxying data from client to pipe: %s", data)

    r.in <- []byte(data)
}

// ControlSequence is a dnode.Function that is exposed to the client,
// allowing them to send control character sequences to an Exec instance.
func (r *Exec) ControlSequence(d *dnode.Partial) {
    data := d.MustSliceOfLength(1)[0].MustString()

    // writer, err := charset.NewWriter("ISO-8859-1", r.in)
    // if err != nil {
    //     fmt.Println(err)
    // }
    //
    // writer.Write([]byte(data))
    r.in <- []byte(data)
}

// Kill is a dnode.Function that is exposed to clients, allowing
// them to kill the Exec instance.
func (r *Exec) Kill(d *dnode.Partial) {
    _ = r.cmd.Process.Kill()
}
