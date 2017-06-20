package proxy

import (
    "os/exec"

    "github.com/koding/kite/dnode"
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
    Output          dnode.Function
    SessionEnded    dnode.Function
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

    r.in <- []byte(data)
}

// ControlSequence is a dnode.Function that is exposed to the client,
// allowing them to send control character sequences to an Exec instance.
func (r *Exec) ControlSequence(d *dnode.Partial) {
    r.Input(d)
}

func (r *Exec) Close(d *dnode.Partial) {

    // The proxy goroutines that are proxying i/o to and from
    // the exec'd process will terminate when the input channel
    // is closed.
    close(r.in)
}

func (r *Exec) Terminate(d *dnode.Partial) {
    r.Close(d)
}
