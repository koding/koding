package tunnel

import (
	"fmt"
	"net"
	"strings"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/tunnel"
	"github.com/koding/klient/protocol"
)

type registerResult struct {
	VirtualHost string
	Identifier  string
}

func Start(k *kite.Kite, conf *tunnel.ClientConfig) error {
	tunnelkite := kite.New("tunnelclient", "0.0.1")
	tunnelkite.Config = k.Config.Copy()
	if conf.Debug {
		tunnelkite.SetLogLevel(kite.DEBUG)
	}

	// Change tunnel server based on environment
	if conf.ServerAddr == "" {
		switch protocol.Environment {
		case "development":
			conf.ServerAddr = "devtunnelproxy.koding.com"
		case "production":
			conf.ServerAddr = "tunnelproxy.koding.com"
		default:
			return fmt.Errorf("Tunnel server address is empty. No env found: %s",
				protocol.Environment)
		}
	}

	// Check if the addr is valid IP, the user might pass to us a valid IP.  If
	// it's not valid, we're going to resolve to the first addr we get.
	if net.ParseIP(conf.ServerAddr) == nil {
		k.Log.Debug("Resolving '%s'", conf.ServerAddr)
		resolved, err := resolvedAddr(conf.ServerAddr)
		if err != nil {
			// just log if we couldn't resolve it
			k.Log.Warning("couldn't resolve '%s: %s", conf.ServerAddr, err)
		} else {
			k.Log.Debug("Address resolved to '%s'", resolved)
			conf.ServerAddr = resolved
		}
	}

	// TODO(arslan): store resolved IP to boltdb and use it

	// append port if absent
	conf.ServerAddr = addPort(conf.ServerAddr, "80")

	k.Log.Debug("Connecting to tunnel server IP: '%s'", conf.ServerAddr)
	tunnelserver := tunnelkite.NewClient("http://" + conf.ServerAddr + "/kite")
	// Enable it later if needed
	// tunnelserver.LocalKite.Config.Transport = config.XHRPolling

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

func resolvedAddr(host string) (string, error) {
	addr, err := net.LookupHost(host)
	if err != nil {
		return "", err
	}

	if len(addr) == 0 {
		return "", fmt.Errorf("no resolved addresses found for '%s'", host)
	}

	return addr[0], nil
}

// hasPort detecths if the given name has a port or not
func hasPort(s string) bool { return strings.LastIndex(s, ":") > strings.LastIndex(s, "]") }

// addPort adds the port and returns "host:port". If the host already contains
// a port, it returns it.
func addPort(host, port string) string {
	if ok := hasPort(host); ok {
		return host
	}

	return host + ":" + port
}
