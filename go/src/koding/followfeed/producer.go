package main

import (
	"github.com/streadway/amqp"
	"koding/tools/amqputil"
	"strconv"
)

var scale int = 1e4

func userNum(i int) string {
	return "user" + strconv.Itoa(i)
}

func main() {
	startPublishing()
}

func startPublishing() {
	conn := amqputil.CreateConnection("ffproduce")
	channel := amqputil.CreateChannel(conn)

	for i := 0; i < scale; i++ {

		key := userNum(i)

		if err := channel.Publish(
			key,   // exchange
			key,   // routing key
			false, // mandatory
			false, // immediate
			amqp.Publishing{
				Headers:         amqp.Table{},
				ContentType:     "text/plain",
				ContentEncoding: "",
				Body:            []byte("hello to " + key),
				DeliveryMode:    amqp.Transient, // 1=non-persistent, 2=persistent
				Priority:        0,              // 0-9
				// a bunch of application/implementation-specific fields
			},
		); err != nil {
			panic(err)
		}
	}
}
