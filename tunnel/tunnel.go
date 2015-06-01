package tunnel

import (
	"errors"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/tunnel"
)

type registerResult struct {
	VirtualHost string
	Identifier  string
}

func Start(k *kite.Kite, conf *tunnel.ClientConfig) error {
	if conf.ServerAddr == "" {
		return errors.New("Tunnel server addr is empty")
	}

	tunnelserver := k.NewClient("http://" + conf.ServerAddr + "/kite")
	connected, err := tunnelserver.DialForever()
	if err != nil {
		return err
	}

	<-connected

	conf.FetchIdentifier = func() (string, error) {
		result, err := callRegister(tunnelserver)
		if err != nil {
			return "", err
		}

		k.Log.Info("Our tunnel public host is: '%s'", result.VirtualHost)
		return result.Identifier, nil
	}

	client, err := tunnel.NewClient(conf)
	if err != nil {
		return err
	}

	go client.Start()
	return nil
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
