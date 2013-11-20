package tunnel

import (
	"io"
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
