package moh

import (
	"log"
	"net"
	"net/http"
)

type CloseableServer struct {
	listener net.Listener
	Mux      *http.ServeMux
}

// NewClosableServer returns a pointer to a new ClosableServer.
// After creation, handlers can be registered on Mux and the server
// can be started with Serve() function. Then, you can close it with Close().
func NewClosableServer(addr string) (*CloseableServer, error) {
	l, err := net.Listen("tcp", addr)
	if err != nil {
		return nil, err
	}

	return &CloseableServer{
		listener: l,
		Mux:      http.NewServeMux(),
	}, nil
}

func (s *CloseableServer) Serve() {
	http.Serve(s.listener, s.Mux)
	log.Println("Serving has finished")
}

func (s *CloseableServer) Close() error {
	return s.listener.Close()
}
