package streamtunnel

import (
	"sync"

	"github.com/hashicorp/yamux"
)

type Server struct {
	// sessions contains a session per virtual host. Sessions provides
	// multiplexing over one connection
	sessions   map[string]*yamux.Session
	sessionsMu sync.Mutex // protects the sessions map

	// virtualHosts is used to map public hosts to remote clients
	virtualHosts *virtualHosts
}

func NewServer() *Server {
	s := &Server{
		sessions:     make(map[string]*yamux.Session),
		virtualHosts: newVirtualHosts(),
	}

	return s
}

func (s *Server) AddHost(host, identifier string) {
	s.virtualHosts.addHost(host, identifier)
}

func (s *Server) DeleteHost(host, identifier string) {
	s.virtualHosts.deleteHost(host)
}

func (s *Server) GetIdentifier(host string) (string, bool) {
	identifier, ok := s.virtualHosts.getIdentifier(host)
	return identifier, ok
}

func (s *Server) GetHost(identifier string) (string, bool) {
	host, ok := s.virtualHosts.getHost(identifier)
	return host, ok
}
