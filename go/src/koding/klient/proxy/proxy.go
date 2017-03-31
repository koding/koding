package proxy

import (
    "github.com/koding/kite"
)

type Machine struct {
    Id  string  `json:"id"`
}

type MachinesResponse struct {
    Machines    []Machine   `json:"machines"`
}

type Proxy interface {

    // List is a kite handler for the "proxy.list" method.
    //
    // Returns a *MachinesResponse representing machines that klient
    // is responsible for proxying commands to.
    List(*kite.Request) (interface{}, error)

}
