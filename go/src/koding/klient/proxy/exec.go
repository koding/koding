package proxy

import (
    "io"
    "os/exec"

    "github.com/koding/kite/dnode"
)

// ExecRequest is a helper type to verify the
// request to the "proxy.exec" kite endpoint.
type ExecRequest struct {
    Session     string          `json:"session"`
    Command     []string        `json:"command"`

    Output      dnode.Function
    Done        dnode.Function
}

// ExecKubernetesRequest is a helper type to verify requests to the
// "proxy.exec" kite endpoint, when we are proxying to K8s containers.
type ExecKubernetesRequest struct {
    ExecRequest

    Namespace   string
    Pod         string
    Container   string
}

// Exec is the server side representation of a command
// that was exec'ed by this client into some context
// depending on what the current proxy type is.
type Exec struct {
    Session     string          `json:"session"`
    Command     []string        `json:"command"`

    cmd         *exec.Cmd
    in          io.WriteCloser
}

// ExecResponse is a helper type for clients to Unmarshal
// the response from the "proxy.exec" kite method. It is
// the client-side representation of the Exec type.
type ExecResponse struct {
    Session     string
    Command     []string        `json:"command"`

    Input       dnode.Function
    Kill        dnode.Function
}

// Input is a dnode.Function that is exposed to the client, allowing
// them to send data to an Exec instance.
func (r *Exec) Input(d *dnode.Partial) {
    data := d.MustSliceOfLength(1)[0].MustString()

    r.in.Write([]byte(data))
}

// Kill is a dnode.Function that is exposed to clients, allowing
// them to kill the Exec instance.
func (r *Exec) Kill(d *dnode.Partial) {
    _ = r.cmd.Process.Kill()
}
