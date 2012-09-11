package kite

import (
	"github.com/streadway/amqp"
	"io"
	"koding/tools/dnode"
	"koding/tools/log"
	"strings"
	"time"
)

type connection struct {
	messageStream   <-chan amqp.Delivery
	publishChannel  *amqp.Channel
	replyExchange   string
	bufferedMessage []byte
}

func (conn *connection) Read(p []byte) (int, error) {
	if len(conn.bufferedMessage) == 0 {
		message, ok := <-conn.messageStream
		if !ok {
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
	log.Debug("Write", p)
	err := conn.publishChannel.Publish(conn.replyExchange, "reply-client-message", false, false, amqp.Publishing{Body: p})
	if err != nil {
		return 0, err
	}
	return len(p), nil
}

func Start(uri, name string, onRootMethod func(user, method string, args interface{}) interface{}) {
	for {
		func() {
			defer time.Sleep(10 * time.Second)
			defer log.RecoverAndLog()

			log.Info("Connecting to AMQP server...")

			consumeConn := createConn(uri)
			defer consumeConn.Close()

			publishConn := createConn(uri)
			defer publishConn.Close()

			log.Info("Successfully connected to AMQP server.")

			joinStream, joinChannel := declareBindConsumeQueue(consumeConn, "kite-"+name, "join", "private-kite-"+name)
			defer joinChannel.Close()

			for join := range joinStream {
				go func() {
					defer log.RecoverAndLog()

					secretName := string(join.Body)
					user := strings.Split(secretName, ".")[1]

					log.Info("Client connected: " + user)

					messageChannel := createChannel(consumeConn)
					defer messageChannel.Close()
					messageStream, err := messageChannel.Consume(secretName, "", true, false, false, false, nil)
					if err != nil {
						panic(err)
					}

					publishChannel := createChannel(consumeConn)
					defer publishChannel.Close()

					node := dnode.New(&connection{messageStream, publishChannel, "reply-" + secretName, make([]byte, 0)})
					node.OnRootMethod = func(method string, args []interface{}) {
						result := onRootMethod(user, method, args[0].(map[string]interface{})["withArgs"])
						if result != nil {
							args[1].(dnode.Callback)(result)
						}
					}
					node.Run()
				}()
			}

			log.Warn("Connection to AMQP server lost.")
		}()
	}
}

func createConn(uri string) *amqp.Connection {
	conn, err := amqp.Dial(uri)
	if err != nil {
		panic(err)
	}
	return conn
}

func createChannel(conn *amqp.Connection) *amqp.Channel {
	channel, err := conn.Channel()
	if err != nil {
		panic(err)
	}
	return channel
}

func declareBindConsumeQueue(conn *amqp.Connection, queue, key, exchange string) (<-chan amqp.Delivery, *amqp.Channel) {
	channel := createChannel(conn)

	err := channel.ExchangeDeclare(exchange, "topic", true, true, false, false, nil)
	if err != nil {
		panic(err)
	}

	_, err = channel.QueueDeclare(queue, false, true, false, false, nil)
	if err != nil {
		panic(err)
	}

	err = channel.QueueBind(queue, key, exchange, false, nil)
	if err != nil {
		panic(err)
	}

	stream, err := channel.Consume(queue, "", true, false, false, false, nil)
	if err != nil {
		panic(err)
	}

	return stream, channel
}
