// Package moh provides mechanisms for messaging over HTTP connection.
// While Requester and Replier talk via HTTP synchronously,
// Subscriber and Publisher talk via Websocket protocol asynchronously.
package moh

import (
	"net/http"
)

const (
	DefaultPath = "/_moh_/"

	// DefaultReplierPath is the default path for Replier that
	// NewMessagingClient() registers the handler on.
	DefaultReplierPath = DefaultPath + "rep"

	// DefaultPublisherPath is the default path for Publisher that
	// NewMessagingClient() registers the handler on.
	DefaultPublisherPath = DefaultPath + "pub"
)

// MessagingClient is a type that combines the usage of the
// Requester and Subscriber.
type MessagingClient struct {
	*Requester
	*Subscriber
}

// NewMessagingClient returns a pointer to new MessagingClient.
// The client will connect the server from the default paths.
// Connect() needs to be called explicitly to consume the messages from
// the server.
func NewMessagingClient(addr string, consumeFunc func([]byte)) *MessagingClient {
	replierURL := "http://" + addr + DefaultReplierPath
	publisherURL := "ws://" + addr + DefaultPublisherPath
	return &MessagingClient{
		Requester:  NewRequester(replierURL),
		Subscriber: NewSubscriber(publisherURL, consumeFunc),
	}
}

// MessagingServer is a type that combines a Replier and a Publisher
// on one server. Server is a CloseableServer that can be stopped with
// Close() method.
type MessagingServer struct {
	*CloseableServer
	*Replier
	*Publisher
}

// NewMessagingServer returns a pointer to new MessagingServer.
// To start the server it is necessary to invoke ListenAndServe(),
// typically in a go statement.
func NewMessagingServer(replyFunc func([]byte) []byte) *MessagingServer {
	s := &MessagingServer{
		CloseableServer: NewCloseableServer(),
		Replier:         NewReplier(replyFunc),
		Publisher:       NewPublisher(),
	}
	s.Handle(DefaultReplierPath, s.Replier)
	s.Handle(DefaultPublisherPath, s.Publisher)
	return s
}

// ServeHTTP implements http.Handler. Delegates all requests to ServeMux.
func (s *MessagingServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	s.ServeMux.ServeHTTP(w, r)
}
