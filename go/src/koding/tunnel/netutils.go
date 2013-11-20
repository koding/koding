package tunnel

import (
	"io"
	"log"
	"net"
	"net/http"
	"strings"
)

func join(local, remote io.ReadWriteCloser) chan error {
	errc := make(chan error, 2)

	copy := func(dst io.Writer, src io.Reader) {
		_, err := io.Copy(dst, src)
		errc <- err
	}

	go copy(local, remote)
	go copy(remote, local)

	return errc
}

func dialTCP(addr string) *net.TCPConn {
	serverTcpAddr, err := net.ResolveTCPAddr("tcp4", addr)
	if err != nil {
		log.Fatalf("server addr %s\n", err)
	}

	conn, err := net.DialTCP("tcp", nil, serverTcpAddr)
	if err != nil {
		log.Fatalf("remote %s\n", err)
	}

	return conn
}

func copyHeader(dst, src http.Header) {
	for k, vv := range src {
		for _, v := range vv {
			dst.Add(k, v)
		}
	}
}

func isWebsocket(req *http.Request) bool {
	if strings.ToLower(req.Header.Get("Upgrade")) != "websocket" ||
		!strings.Contains(strings.ToLower(req.Header.Get("Connection")), "upgrade") {
		return false
	}
	return true
}
