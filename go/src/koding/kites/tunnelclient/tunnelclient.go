package main

import (
	"strings"

	"github.com/koding/kite"
	"github.com/koding/multiconfig"
	"github.com/koding/tunnel"
)

type registerResult struct {
	VirtualHost string
	Identifier  string
}

func main() {
	conf := new(tunnel.ClientConfig)
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

	conf.ServerAddr = addPort(conf.ServerAddr, "80")

	client := tunnel.NewClient(conf)
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

// Given a string of the form "host", "host:port", or "[ipv6::address]:port",
// return true if the string includes a port.
func hasPort(s string) bool { return strings.LastIndex(s, ":") > strings.LastIndex(s, "]") }

// Given a string of the form "host", "port", returns "host:port"
func addPort(host, port string) string {
	if ok := hasPort(host); ok {
		return host
	}

	return host + ":" + port
}
