package tunnel

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
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

type host struct {
	kite     string
	version  string
	username string
}

// parse host into service, version and username. Example:
// webserver-917-fatih.kd.io, returns a host struct with kitename, version and
// username.
func parseHost(url string) (*host, error) {
	// input: xxxxx.kd.io, output: [xxxxx kd.io]
	h := strings.SplitN(url, ".", 2)

	if len(h) != 2 {
		return nil, fmt.Errorf("not valid host '%s'", url)
	}

	if h[1] != "kd.io" {
		return nil, fmt.Errorf("invalid domain: %s", h[1])
	}

	// input: kitename-key-username, output: [service key username]
	s := strings.Split(h[0], "-")
	return &host{
		kite:     s[0],
		version:  s[1],
		username: s[2],
	}, nil
}

// randomID generates a random string of the given length
func randomID(length int) string {
	r := make([]byte, length*6/8)
	rand.Read(r)
	return base64.URLEncoding.EncodeToString(r)
}
