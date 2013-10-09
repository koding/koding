package moh

import (
	"log"
	"net"
	"net/http"
)

type MessagingServer struct {
	listener net.Listener
	Mux      *http.ServeMux
}

// NewClosableServer returns a pointer to a new ClosableServer.
// After creation, handlers can be registered on Mux and the server
// can be started with Serve() function. Then, you can close it with Close().
func NewClosableServer(addr string) (*MessagingServer, error) {
	l, err := net.Listen("tcp", addr)
	if err != nil {
		return nil, err
	}

	return &MessagingServer{
		listener: l,
		Mux:      http.NewServeMux(),
	}, nil
}

func (s *MessagingServer) Serve() {
	http.Serve(s.listener, s.Mux)
	log.Println("Serving has finished")
}

func (s *MessagingServer) Close() error {
	return s.listener.Close()
}
