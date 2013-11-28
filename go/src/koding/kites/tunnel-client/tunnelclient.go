package main

import (
	"flag"
	"fmt"
	"koding/newkite/kite"
	"koding/newkite/protocol"
	"koding/tunnel"
)

type registerResult struct {
	VirtualHost string
	Identifier  string
}

var (
	log  = kite.GetLogger()
	port = flag.String("port", "5000", "port to bind to local server")
)

const serverAddr = "127.0.0.1:7000"

func main() {
	options := &kite.Options{
		Kitename:    "tunnelclient",
		Version:     "1",
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

	result, err := register(tunnelserver)
	if err != nil {
		fmt.Println(err)
		return
	}

	log.Notice("public host : %s", result.VirtualHost)

	client := tunnel.NewClient(serverAddr, ":"+*port)
	client.Start(result.Identifier)
}

func register(tunnelserver *kite.RemoteKite) (*registerResult, error) {
	response, err := tunnelserver.Call("register", nil)
	if err != nil {
		return nil, err
	}

	result := &registerResult{}
	err = response.Unmarshal(result)
	if err != nil {
		return nil, err
	}

	return result, nil
}

func getTunnelServer(k *kite.Kite) *kite.RemoteKite {
	query := protocol.KontrolQuery{
		Username: "devrim",
		Name:     "tunnelserver",
	}

	kites, err := k.Kontrol.GetKites(query, nil)
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
