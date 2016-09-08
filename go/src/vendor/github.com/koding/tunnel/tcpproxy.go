package tunnel

import (
	"fmt"
	"net"

	"github.com/koding/logging"
	"github.com/koding/tunnel/proto"
)

var (
	tpcLog = logging.NewLogger("tcp")
)

// TCPProxy forwards TCP streams.
//
// If port-based routing is used, LocalAddr or FetchLocalAddr field is required
// for tunneling to function properly.
// Otherwise you'll be forwarding traffic to random ports and this is usually not desired.
//
// If IP-based routing is used then tunnel server connection request is
// proxied to 127.0.0.1:incomingPort where incomingPort is control message LocalPort.
// Usually this is tunnel server's public exposed Port.
// This behaviour can be changed by setting LocalAddr or FetchLocalAddr.
// FetchLocalAddr takes precedence over LocalAddr.
type TCPProxy struct {
	// LocalAddr defines the TCP address of the local server.
	// This is optional if you want to specify a single TCP address.
	LocalAddr string
	// FetchLocalAddr is used for looking up TCP address of the server.
	// This is optional if you want to specify a dynamic TCP address based on incommig port.
	FetchLocalAddr func(port int) (string, error)
	// Log is a custom logger that can be used for the proxy.
	// If not set a "tcp" logger is used.
	Log logging.Logger
}

// Proxy is a ProxyFunc.
func (p *TCPProxy) Proxy(remote net.Conn, msg *proto.ControlMessage) {
	if msg.Protocol != proto.TCP {
		panic("Proxy mismatch")
	}

	var log = p.log()

	var port = msg.LocalPort
	if port == 0 {
		log.Warning("TCP proxy to port 0")
	}

	var localAddr = fmt.Sprintf("127.0.0.1:%d", port)
	if p.LocalAddr != "" {
		localAddr = p.LocalAddr
	} else if p.FetchLocalAddr != nil {
		l, err := p.FetchLocalAddr(msg.LocalPort)
		if err != nil {
			log.Warning("Failed to get custom local address: %s", err)
			return
		}
		localAddr = l
	}

	log.Debug("Dialing local server: %q", localAddr)
	local, err := net.DialTimeout("tcp", localAddr, defaultTimeout)
	if err != nil {
		log.Error("Dialing local server %q failed: %s", localAddr, err)
		return
	}

	Join(local, remote, log)
}

func (p *TCPProxy) log() logging.Logger {
	if p.Log != nil {
		return p.Log
	}
	return tpcLog
}
