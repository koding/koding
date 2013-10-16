// Package moh provides mechanisms for messaging over HTTP connection.
// While Requester and Replier talk via HTTP synchronously,
// Subscriber and Publisher talk via Websocket protocol asynchronously.
package moh

const (
	DefaultReplierPath   = "/_moh_/rep"
	DefaultPublisherPath = "/_moh_/pub"
)

type MessagingClient struct {
	*Requester
	*Subscriber
}

func NewMessagingClient(addr string, consumeFunc func([]byte)) *MessagingClient {
	replierURL := "http://" + addr + DefaultReplierPath
	publisherURL := "ws://" + addr + DefaultPublisherPath
	return &MessagingClient{
		Requester:  NewRequester(replierURL),
		Subscriber: NewSubscriber(publisherURL, consumeFunc),
	}
}

type MessagingServer struct {
	*CloseableServer
	*Replier
	*Publisher
}

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
