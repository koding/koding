package e2etest

import (
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/koding/kite/sockjsclient"
)

var defaultTransport = &http.Transport{
	Proxy: http.ProxyFromEnvironment,
	Dial: (localDialer{
		Dialer: &net.Dialer{
			Timeout:   30 * time.Second,
			KeepAlive: 30 * time.Second,
		},
	}).Dial,
	TLSHandshakeTimeout: 10 * time.Second,
}

var defaultClient = &http.Client{
	Transport: defaultTransport,
}

type debugListener struct {
	net.Listener
}

type debugConn struct {
	net.Conn
}

type localDialer struct {
	*net.Dialer
}

func (dl debugListener) Accept() (net.Conn, error) {
	conn, err := dl.Listener.Accept()
	if err != nil {
		return nil, err
	}
	return debugConn{conn}, nil
}

func (dc debugConn) Write(p []byte) (int, error) {
	fmt.Println("debugConn.Write:")
	return io.MultiWriter(dc.Conn, os.Stderr).Write(p)
}

func (dc debugConn) Read(p []byte) (int, error) {
	fmt.Println("debugConn.Read")
	return io.TeeReader(dc.Conn, os.Stderr).Read(p)
}

func (ld localDialer) Dial(network, addr string) (net.Conn, error) {
	if strings.HasSuffix(addr, ".localhost") {
		addr = "localhost"
	}

	return ld.Dialer.Dial(network, addr)
}

func newClientFunc() func(*sockjsclient.DialOptions) *http.Client {
	jar, _ := cookiejar.New(nil)
	client := &http.Client{
		Transport: defaultTransport,
		Jar:       jar,
	}
	return func(*sockjsclient.DialOptions) *http.Client {
		return client
	}

}

func host(s string) string {
	u, err := url.Parse(s)
	if err != nil {
		panic(err)
	}
	return u.Host
}

func port(s string) string {
	_, port, err := net.SplitHostPort(s)
	if err != nil {
		panic(err)
	}
	return port
}
