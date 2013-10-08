package moh

import (
	"log"
	"net"
	"net/http"
)

type CloseableServer struct {
	listener net.Listener
	mux      *http.ServeMux
}

func NewClosableServer(addr string) (*CloseableServer, error) {
	l, err := net.Listen("tcp", addr)
	if err != nil {
		return nil, err
	}

	return &CloseableServer{
		listener: l,
		mux:      http.NewServeMux(),
	}, nil
}

func (s *CloseableServer) serve() {
	http.Serve(s.listener, s.mux)
	log.Println("Serving has finished")
}

func (s *CloseableServer) Close() error {
	return s.listener.Close()
}
