package moh

import (
	"log"
	"net"
	"net/http"
	"strings"
)

// MessagingServer is a base for Replier and Publisher structs.
// It is a closeable HTTP server. You can shutdown it gracefully with Close().
type MessagingServer struct {
	listener net.Listener
	*http.ServeMux
}

// An error string equivalent to net.errClosing for using with http.Serve()
// during a graceful exit.  It was not exported by "net" package, so I had to
// put it here.
const errClosing = "use of closed network connection"

// NewMessagingServer returns a pointer to a new MessagingServer.  After
// creation, handlers can be registered on Mux and the server can be started
// with Serve() function. Then, you can close it with Close().
func NewMessagingServer() *MessagingServer {
	return &MessagingServer{ServeMux: http.NewServeMux()}
}

// ListenAndServe runs the HTTP server until it is closed by Close() method.
func (s *MessagingServer) ListenAndServe(addr string) error {
	var err error

	s.listener, err = net.Listen("tcp", addr)
	if err != nil {
		return err
	}
	log.Printf("Listening on: %s\n", s.Addr())

	err = http.Serve(s.listener, s)
	if strings.Contains(err.Error(), errClosing) {
		// The server is closed by Close() method
		log.Println("Serving has finished")
	} else {
		log.Println("Cannot start server on ", s.Addr())
		return err
	}

	return nil
}

// Close make the server stop accepting new connections.
// Established connections will remain open until their handler finishes.
func (s *MessagingServer) Close() error {
	return s.listener.Close()
}

// Addr returns the address that the server listens on.
func (s *MessagingServer) Addr() net.Addr {
	return s.listener.Addr()
}
