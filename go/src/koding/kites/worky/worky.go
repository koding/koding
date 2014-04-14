package main

import (
	"fmt"
	"github.com/koding/kite"
	"github.com/koding/kite/kontrolclient"
	"github.com/koding/kite/protocol"
	"koding/kodingkite"
	"koding/tools/config"
)

func main() {
	c := config.MustConfig("vagrant")
	k := kodingkite.New(c, "worky", "0.0.1")
	kc := kontrolclient.New(k.Kite)
	kc.Dial()
	query := protocol.KontrolQuery{Username: "devrim", Environment: "vagrant"}
	kc.WatchKites(query, func(e *kontrolclient.Event, err *kite.Error) {
		fmt.Println(e.Action)
	})
	select {}
}
