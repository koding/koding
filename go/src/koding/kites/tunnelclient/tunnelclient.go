package main

import (
	"errors"
	"flag"
	"fmt"
	"github.com/op/go-logging"
	"koding/kite"
	"koding/kite/protocol"
	"koding/tunnel"
)

type registerResult struct {
	VirtualHost string
	Identifier  string
}

var (
	log  *logging.Logger
	port = flag.String("port", "5000", "port to bind to local server")
)

const serverAddr = "newkontrol.sj.koding.com:80"

func main() {
	flag.Parse()

	options := &kite.Options{
		Kitename:    "tunnelclient",
		Version:     "0.0.3",
		Region:      "localhost",
		Environment: "development",
		KontrolAddr: "newkontrol.sj.koding.com:4000",
	}

	k := kite.New(options)
	log = k.Log
	k.Start()

	tunnelserver, err := getTunnelServer(k)
	if err != nil {
		log.Error(err.Error())
		return
	}

	err = tunnelserver.Dial()
	if err != nil {
		log.Error("cannot connect to tunnelserver")
		return
	}

	result, err := callRegister(tunnelserver)
	if err != nil {
		fmt.Println(err)
		return
	}

	log.Notice("started. your public host is:  '%s'", result.VirtualHost)

	client := tunnel.NewClient(serverAddr, ":"+*port)
	client.Start(result.Identifier)
}

func callRegister(tunnelserver *kite.RemoteKite) (*registerResult, error) {
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

func getTunnelServer(k *kite.Kite) (*kite.RemoteKite, error) {
	query := protocol.KontrolQuery{
		Username:    "arslan",
		Environment: "development",
		Name:        "tunnelserver",
	}

	kites, err := k.Kontrol.GetKites(query, nil)
	if err != nil {
		return nil, err
	}

	if len(kites) == 0 {
		return nil, errors.New("no tunnelserver available")
	}

	return kites[0], nil
}
