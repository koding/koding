package main

import (
	"errors"
	"fmt"

	"github.com/coreos/go-log/log"
	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
	"github.com/koding/multiconfig"
	"github.com/koding/tunnel"
)

type registerResult struct {
	VirtualHost string
	Identifier  string
}

const serverAddr = "newkontrol.sj.koding.com:80"

type config struct {
	Port string
}

func main() {
	conf := new(config)
	multiconfig.New().MustLoad(conf)

	k := kite.New("tunnelclient", "0.0.1")
	go k.Run()
	<-k.ServerReadyNotify()

	tunnelserver, err := getTunnelServer(k)
	if err != nil {
		k.Log.Error(err.Error())
		return
	}

	err = tunnelserver.Dial()
	if err != nil {
		k.Log.Error("cannot connect to tunnelserver")
		return
	}

	result, err := callRegister(tunnelserver)
	if err != nil {
		fmt.Println(err)
		return
	}

	log.Notice("started. your public host is:  '%s'", result.VirtualHost)

	client := tunnel.NewClient(serverAddr, ":"+conf.Port)
	client.Start(result.Identifier)
}

func callRegister(tunnelserver *kite.Client) (*registerResult, error) {
	response, err := tunnelserver.Tell("register", nil)
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

func getTunnelServer(k *kite.Kite) (*kite.Client, error) {
	query := &protocol.KontrolQuery{
		Username:    "arslan",
		Environment: "development",
		Name:        "tunnelserver",
	}

	kites, err := k.GetKites(query)
	if err != nil {
		return nil, err
	}

	if len(kites) == 0 {
		return nil, errors.New("no tunnelserver available")
	}

	return kites[0], nil
}
