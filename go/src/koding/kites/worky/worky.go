package main

import (
	"fmt"
	"koding/kodingkite"
	"koding/tools/config"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
)

func main() {
	c := config.MustConfig("vagrant")
	k := kodingkite.New(c, "worky", "0.0.1")

	query := protocol.KontrolQuery{Username: "devrim", Environment: "vagrant"}
	k.WatchKites(query, func(e *kite.Event, err *kite.Error) {
		fmt.Println(e.Action)
	})

	select {}
}
