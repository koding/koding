package tunnel

import (
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"net"
	"net/http"

	"github.com/koding/logging"
	"github.com/koding/tunnel/proto"
)

var (
	httpLog = logging.NewLogger("http")
)

// HTTPProxy forwards HTTP traffic.
//
// When tunnel server requests a connection it's proxied to 127.0.0.1:incomingPort
// where incomingPort is control message LocalPort.
// Usually this is tunnel server's public exposed Port.
// This behaviour can be changed by setting LocalAddr or FetchLocalAddr.
// FetchLocalAddr takes precedence over LocalAddr.
//
// When connection to local server cannot be established proxy responds with http error message.
type HTTPProxy struct {
	// LocalAddr defines the TCP address of the local server.
	// This is optional if you want to specify a single TCP address.
	LocalAddr string
	// FetchLocalAddr is used for looking up TCP address of the server.
	// This is optional if you want to specify a dynamic TCP address based on incommig port.
	FetchLocalAddr func(port int) (string, error)
	// ErrorResp is custom response send to tunnel server when client cannot
	// establish connection to local server. If not set a default "no local server"
	// response is sent.
	ErrorResp *http.Response
	// Log is a custom logger that can be used for the proxy.
	// If not set a "http" logger is used.
	Log logging.Logger
}

// Proxy is a ProxyFunc.
func (p *HTTPProxy) Proxy(remote net.Conn, msg *proto.ControlMessage) {
	if msg.Protocol != proto.HTTP && msg.Protocol != proto.WS {
		panic("Proxy mismatch")
	}

	var log = p.log()

	var port = msg.LocalPort
	if port == 0 {
		port = 80
	}

	var localAddr = fmt.Sprintf("127.0.0.1:%d", port)
	if p.LocalAddr != "" {
		localAddr = p.LocalAddr
	} else if p.FetchLocalAddr != nil {
		l, err := p.FetchLocalAddr(msg.LocalPort)
		if err != nil {
			log.Warning("Failed to get custom local address: %s", err)
			p.sendError(remote)
			return
		}
		localAddr = l
	}

	log.Debug("Dialing local server %q", localAddr)
	local, err := net.DialTimeout("tcp", localAddr, defaultTimeout)
	if err != nil {
		log.Error("Dialing local server %q failed: %s", localAddr, err)
		p.sendError(remote)
		return
	}

	Join(local, remote, log)
}

func (p *HTTPProxy) sendError(remote net.Conn) {
	var w = noLocalServer()
	if p.ErrorResp != nil {
		w = p.ErrorResp
	}

	buf := new(bytes.Buffer)
	w.Write(buf)
	if _, err := io.Copy(remote, buf); err != nil {
		var log = p.log()
		log.Debug("Copy in-mem response error: %s", err)
	}

	remote.Close()
}

func noLocalServer() *http.Response {
	body := bytes.NewBufferString("no local server")
	return &http.Response{
		Status:        http.StatusText(http.StatusServiceUnavailable),
		StatusCode:    http.StatusServiceUnavailable,
		Proto:         "HTTP/1.1",
		ProtoMajor:    1,
		ProtoMinor:    1,
		Body:          ioutil.NopCloser(body),
		ContentLength: int64(body.Len()),
	}
}

func (p *HTTPProxy) log() logging.Logger {
	if p.Log != nil {
		return p.Log
	}
	return httpLog
}
