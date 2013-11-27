package main

import (
	"flag"
	"fmt"
	"koding/newkite/kite"
	"koding/newkite/protocol"
)

var port = flag.String("port", "", "port to bind itself")

func main() {
	options := &protocol.Options{
		Kitename:    "tunnelclient",
		Version:     "1",
		Port:        *port,
		Region:      "localhost",
		Environment: "development",
	}

	k := kite.New(options)
	k.Start()

	tunnelserver := getTunnelServer(k)
	if tunnelserver == nil {
		fmt.Println("tunnelServer is nil")
		return
	}

	err := tunnelserver.Dial()
	if err != nil {
		fmt.Println("cannot connect to tunnelserver")
		return
	}

	makeCall(tunnelserver)
}

func makeCall(tunnelserver *kite.RemoteKite) {
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

func getTunnelServer(k *kite.Kite) *kite.RemoteKite {
	query := protocol.KontrolQuery{
		Username: "devrim",
		Name:     "tunnelserver",
	}

	kites, err := k.Kontrol.GetKites(query)
	if err != nil {
		fmt.Println(err)
		return nil
	}

	if len(kites) == 0 {
		fmt.Println("no tunnelserver available")
		return nil
	}

	return kites[0]
}
