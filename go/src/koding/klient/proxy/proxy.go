package proxy

import (
    "github.com/koding/kite"
)

type Proxy interface {

    // List is a kite handler for the "proxy.list" method.
    //
    // Returns a *MachinesResponse representing machines that klient
    // is responsible for proxying commands to.
    List(*kite.Request) (interface{}, error)

}
