package main

import (
	"fmt"

	"github.com/koding/kite"
	"github.com/koding/kite/kontrolclient"
	"github.com/koding/kite/protocol"
	"github.com/koding/kite/simple"
)

func main() {
	k := simple.New("watcher", "1.0.0")
	kc := kontrolclient.New(k.Kite)
	kc.Dial()
	query := protocol.KontrolQuery{
		Username: k.Config.Username,
		// Environment: k.Config.Environment,
	}
	kc.WatchKites(query, onEvent)
	select {}
}

func onEvent(e *kontrolclient.Event, err *kite.Error) {
	fmt.Printf("--- e: %+v %+v\n", e.Action, e.Kite.Name)
}
