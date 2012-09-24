package kite

import (
	"github.com/streadway/amqp"
	"io"
	"koding/tools/log"
	"sync"
)

type connection struct {
	messageChannel  *amqp.Channel
	messageStream   <-chan amqp.Delivery
	publishChannel  *amqp.Channel
	replyExchange   string
	bufferedMessage []byte
	closed          bool
	closers         []io.Closer
	closeMutex      sync.Mutex
}

func newConnection(queue, replyExchange string, consumeConn, publishConn *amqp.Connection) *connection {
	messageChannel := createChannel(consumeConn)
	messageStream, err := messageChannel.Consume(queue, "", true, false, false, false, nil)
	if err != nil {
		panic(err)
	}

	return &connection{
		messageChannel:  messageChannel,
		messageStream:   messageStream,
		publishChannel:  createChannel(publishConn),
		replyExchange:   replyExchange,
		bufferedMessage: make([]byte, 0),
		closers:         make([]io.Closer, 0),
	}
}

func (conn *connection) Read(p []byte) (int, error) {
	if len(conn.bufferedMessage) == 0 {
		message, ok := <-conn.messageStream
		if !ok || message.RoutingKey == "disconnected" {
			return 0, io.EOF
		}
		conn.bufferedMessage = message.Body
		log.Debug("Read", message.Body)
	}
	n := copy(p, conn.bufferedMessage)
	conn.bufferedMessage = conn.bufferedMessage[n:]
	return n, nil
}

func (conn *connection) Write(p []byte) (int, error) {
	conn.closeMutex.Lock()
	defer conn.closeMutex.Unlock()

	if conn.closed {
		return 0, nil
	}
	log.Debug("Write", p)
	err := conn.publishChannel.Publish(conn.replyExchange, "reply-client-message", false, false, amqp.Publishing{Body: p})
	if err != nil {
		panic(err)
	}
	return len(p), nil
}

func (conn *connection) Close() error {
	conn.closeMutex.Lock()
	defer conn.closeMutex.Unlock()

	conn.closed = true
	go func() {
		for _ = range conn.messageStream { // workaround: consume all remaining messages
		}
	}()
	for _, closer := range conn.closers {
		closer.Close()
	}
	conn.messageChannel.Close()
	conn.publishChannel.Close()
	return nil
}

func (conn *connection) notifyClose(closer io.Closer) {
	conn.closers = append(conn.closers, closer)
}
