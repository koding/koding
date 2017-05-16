package proxy

import (
    "os/exec"

    "koding/klient/registrar"
    "koding/klient/util"

    "github.com/koding/kite"
)

var _ Proxy = (*LocalProxy)(nil)

type LocalProxy struct {}

func (p *LocalProxy) Type() ProxyType {
    return Local
}

func (p *LocalProxy) Methods() []string {
    data := []string{}

    for _, e := range registrar.Methods() {
        data = append(data, e)
    }

    return data
}

func (p *LocalProxy) List(r *kite.Request) (interface{}, error) {
    var req *ListRequest

    if err := r.Args.One().Unmarshal(&req); err != nil {
        return nil, err
    }

    res, err := p.list(req)
    if err != nil {
        return nil, err
    }

    return res, nil
}

func (p *LocalProxy) list(r *ListRequest) (*ListResponse, error) {
    data := &ListResponse{}

    return data, nil
}

func (p *LocalProxy) Exec(r *kite.Request) (interface{}, error) {
    var req *ExecRequest

    if err := r.Args.One().Unmarshal(&req); err != nil {
        return nil, err
    }

    res, err := p.exec(req)
    if err != nil {
        return nil, err
    }

    return res, nil
}

func (p *LocalProxy) exec(r *ExecRequest) (*Exec, error) {

    // TODO (acbodine): Check for existence of at least a Command to run.

    // Validate that Output dnode.Function is valid.
    if !r.Output.IsValid() {
        err := r.Output.Call(nil)
        return nil, err
    }

    cmd := exec.Command(r.Common.Command[0], r.Common.Command[1:]...)
    cPipes, err := util.GetPipes(cmd)
    if err != nil {
        return nil, err
    }

    inChan := make(chan []byte)
    go func() {
        for {
            select {
                case d := <- inChan:
                    cPipes.In.Write(d)
            }
        }
    }()

    // Send all data from cmd output pipe to the requesting client, via
    // the Output dnode.Function provided by the requester.
    go func() {
        _ = util.PassTo(r.Output, cPipes.Out)
    }()

    // Send all data from cmd error pipe to the requesting client, via
    // the Output dnode.Function provided by the requester.
    go func() {
        _ = util.PassTo(r.Output, cPipes.Err)
    }()

    if err = cmd.Start(); err != nil {
        return nil, err
    }

    go func() {
        _ = cmd.Wait()

        _ = r.Done.Call(true)
    }()

    data := &Exec{
        cmd:        cmd,
        in:         inChan,

        Common:     r.Common,
        IO:         r.IO,
    }

    return data, nil
}
