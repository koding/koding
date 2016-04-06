package discovertest

import (
	"encoding/json"
	"koding/kites/tunnelproxy/discover"
	"net"
	"net/http"
	"strings"
)

// Server is a tunnel's /-/discover/:service server listening on a system-chosen
// port on the local loopback interface.

// It is used for end-to-end tunnel clients tests.
type Server map[string]discover.Endpoints

// ServeHTTP implements the http.Handler interface.
//
// It returns JSON-encoded list of endpoints for a given service.
// If no endpoints exists for the given service, it responds with
// status code 400.
func (s Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if !strings.HasPrefix(r.URL.Path, "/-/discover/") {
		http.Error(w, http.StatusText(400), 400)
		return
	}

	service := strings.TrimPrefix(r.URL.Path, "/-/discover/")

	e, ok := s[service]
	if !ok {
		http.Error(w, "service not found: "+service, 400)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(e)
}

// Start starts serving the discover requests on random port.
//
// The returned listener can be used to obtain the server's network
// address and eventually close it.
func (s Server) Start() (net.Listener, error) {
	l, err := net.Listen("tcp4", "127.0.0.1:0")
	if err != nil {
		return nil, err
	}

	lis := NewListener(l)

	go http.Serve(lis, s)

	lis.Wait()

	return l, nil
}
