package kite

import (
	"github.com/streadway/amqp"
	"io"
	"koding/tools/log"
)

type connection struct {
	messageStream   <-chan amqp.Delivery
	publishChannel  *amqp.Channel
	replyExchange   string
	replyKey        string
	bufferedMessage []byte
}

func (conn *connection) Read(p []byte) (int, error) {
	if len(conn.bufferedMessage) == 0 {
		message, ok := <-conn.messageStream
		if !ok {
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
	log.Debug("Write", p)
	err := conn.publishChannel.Publish(conn.replyExchange, conn.replyKey, false, false, amqp.Publishing{Body: p})
	if err != nil {
		return 0, err
	}
	return len(p), nil
}
