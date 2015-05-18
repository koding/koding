package main

import (
	"errors"
	"fmt"

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
	ServerAddr string `default:"127.0.0.1:4444"`
	LocalAddr  string `default:"127.0.0.1:3000"`
}

func main() {
	conf := new(config)
	multiconfig.New().MustLoad(conf)

	k := kite.New("tunnelclient", "0.0.1")
	go k.Run()
	<-k.ServerReadyNotify()

	tunnelserver := k.NewClient("http://" + conf.ServerAddr + "/kite")
	if err := tunnelserver.Dial(); err != nil {
		k.Log.Error(err.Error())
		return
	}

	result, err := callRegister(tunnelserver)
	if err != nil {
		fmt.Println(err)
		return
	}

	k.Log.Info("Our tunnel public host is: '%s'", result.VirtualHost)
	client := tunnel.NewClient(conf.ServerAddr, conf.LocalAddr)
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
