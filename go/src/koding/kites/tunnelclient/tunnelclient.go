package main

import (
	"errors"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
	"github.com/koding/multiconfig"
	"github.com/koding/streamtunnel"
)

type registerResult struct {
	VirtualHost string
	Identifier  string
}

func main() {
	conf := new(streamtunnel.ClientConfig)
	multiconfig.New().MustLoad(conf)

	k := kite.New("tunnelclient", "0.0.1")
	go k.Run()
	<-k.ServerReadyNotify()

	tunnelserver := k.NewClient("http://" + conf.ServerAddr + "/kite")
	connected, err := tunnelserver.DialForever()
	if err != nil {
		k.Log.Error(err.Error())
		return
	}

	<-connected

	if conf.ServerAddr == "" {
		conf.ServerAddr = "127.0.0.1:4444"
	}

	client := streamtunnel.NewClient(conf)
	client.FetchIdentifier = func() (string, error) {
		result, err := callRegister(tunnelserver)
		if err != nil {
			return "", err
		}

		k.Log.Info("Our tunnel public host is: '%s'", result.VirtualHost)
		return result.Identifier, nil
	}
	client.Start()
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
