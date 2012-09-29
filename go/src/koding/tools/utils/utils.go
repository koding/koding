package utils

import (
	"fmt"
	"github.com/streadway/amqp"
	"koding/tools/log"
	"math/rand"
	"os"
	"runtime"
	"time"
)

func DefaultStartup(facility string, needRoot bool) {
	runtime.GOMAXPROCS(runtime.NumCPU())
	rand.Seed(time.Now().UnixNano())
	log.Facility = fmt.Sprintf("$s %d", facility, os.Getpid())

	if needRoot && os.Getuid() != 0 {
		panic("Must be run as root.")
	}
}

func CreateAmqpConnection(uri string) *amqp.Connection {
	conn, err := amqp.Dial(uri)
	if err != nil {
		panic(err)
	}
	return conn
}

func CreateAmqpChannel(conn *amqp.Connection) *amqp.Channel {
	channel, err := conn.Channel()
	if err != nil {
		panic(err)
	}
	return channel
}

func DeclareBindConsumeAmqpQueue(channel *amqp.Channel, queue, key, exchange string, autodelete bool) <-chan amqp.Delivery {
	err := channel.ExchangeDeclare(exchange, "topic", true, true, false, false, nil)
	if err != nil {
		panic(err)
	}

	_, err = channel.QueueDeclare(queue, false, autodelete, false, false, nil)
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

	return stream
}
