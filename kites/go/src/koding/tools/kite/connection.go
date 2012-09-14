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
	replyKey        string
	bufferedMessage []byte
	closed          bool
	closers         []io.Closer
	closeMutex      sync.Mutex
}

func newConnection(secretName string, consumeConn, publishConn *amqp.Connection) *connection {
	messageChannel := createChannel(consumeConn)
	messageStream := declareBindConsumeQueue(messageChannel, "", "client-message.*", secretName, true)
	err := messageChannel.QueueBind("", "disconnected", secretName, false, nil)
	if err != nil {
		panic(err)
	}

	return &connection{
		messageChannel:  messageChannel,
		messageStream:   messageStream,
		publishChannel:  createChannel(publishConn),
		replyExchange:   secretName,
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
		conn.replyKey = "reply-" + message.RoutingKey
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
	err := conn.publishChannel.Publish(conn.replyExchange, conn.replyKey, false, false, amqp.Publishing{Body: p})
	if err != nil {
		panic(err)
	}
	return len(p), nil
}

func (conn *connection) Close() error {
	conn.closeMutex.Lock()
	defer conn.closeMutex.Unlock()

	conn.closed = true
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
