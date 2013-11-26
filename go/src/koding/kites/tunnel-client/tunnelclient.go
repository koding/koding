package main

import (
	"flag"
	"fmt"
	"koding/newkite/kite"
	"koding/newkite/protocol"
	"time"
)

var port = flag.String("port", "", "port to bind itself")

func main() {
	options := &protocol.Options{
		Kitename:    "tunnelclient",
		Version:     "1",
		Port:        *port,
		Region:      "localhost",
		Environment: "development",
		// Username:    "fatih",
	}

	k := kite.New(options)
	go k.Run()

	time.Sleep(1 * time.Second)

	query := protocol.KontrolQuery{
		Username: "devrim",
		Name:     "tunnelserver",
	}

	kites, err := k.Kontrol.GetKites(query)
	if err != nil {
		fmt.Println(err)
		return
	}

	if len(kites) == 0 {
		fmt.Println("no tunnelserver available")
		return
	}

	tunnelserver := kites[0]
	err = tunnelserver.Dial()
	if err != nil {
		fmt.Println("cannot connect to tunnelserver")
		return
	}

	response, err := tunnelserver.Call("register", nil)
	if err != nil {
		fmt.Println(err)
		return
	}

	result, err := response.String()
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println("result is", result)
}
