package main

import (
	"github.com/streadway/amqp"
	"koding/tools/amqputil"
	"log"
	"math/rand"
	"strconv"
)

var scale int = 1e4
var concurrent int = scale / 10 // we assume a very large percentage of concurrent users

func userNum(i int) string {
	return "user" + strconv.Itoa(i)
}

func main() {
	startStressTest()
	select {}
}

func startStressTest() {
	conn := amqputil.CreateConnection("ffconsume")
	channel := amqputil.CreateChannel(conn)
	done := make(chan error)

	var err error

	for i := 0; i < scale; i++ {

		err = channel.ExchangeDeclare(
			userNum(i), // name
			"direct",   // kind
			false,      // durable
			false,      // auto-delete
			false,      // internal
			false,      // no-wait
			nil,        // args
		)

		if err != nil {
			panic(err)
		}
	}

	var bindings int = 0

	for i := 0; i < scale; i++ {
		r := rand.Intn(10)

		source := userNum(i)

		for j := 0; j < r; j++ {
			destination := userNum(rand.Intn(scale))

			channel.ExchangeBind(
				destination, // destination
				destination, // key
				source,      // source
				false,
				nil, // args
			)

			bindings++
		}
	}

	log.Print(strconv.Itoa(bindings) + " E2E bindings created")

	for i := 0; i < concurrent; i++ {

		key := userNum(i)

		channel.QueueDeclare(
			"",    // name
			false, // durable
			true,  // auto-delete
			false, // exclusive
			false, // no-wait
			nil,   // args
		)

		channel.QueueBind(
			"",    // name
			key,   // key
			key,   // exchange
			false, // no-wait
			nil,   // args
		)

		deliveries, err := channel.Consume(
			"",    // name
			"",    // consumer tag
			true,  // auto ack
			false, // exclusive
			false, // no local
			false, // no wait
			nil,   // args
		)

		if err != nil {
			panic(err)
		}

		go handle(deliveries, done)

	}

	log.Print(strconv.Itoa(concurrent) + " queues created and bound")
}

func handle(deliveries <-chan amqp.Delivery, done chan error) {
	for d := range deliveries {
		log.Printf(
			"got %dB delivery: [%v] %s",
			len(d.Body),
			d.DeliveryTag,
			d.Body,
		)
	}
	log.Printf("handle: deliveries channel closed")
	done <- nil
}
