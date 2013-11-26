package main

import (
	"flag"
	"fmt"
	"koding/newkite/kite"
	"koding/newkite/protocol"
)

var port = flag.String("port", "", "port to bind itself")

func main() {
	flag.Parse()

	options := &protocol.Options{
		Kitename:    "tunnelserver",
		Version:     "1",
		Port:        *port,
		Region:      "localhost",
		Environment: "development",
		Username:    "koding",
	}

	k := kite.New(options)
	k.HandleFunc("register", Register)
	k.Run()
}

func Register(r *kite.Request) (interface{}, error) {
	fmt.Printf("tunnelclient made request:", r)
	return "done", nil
}
