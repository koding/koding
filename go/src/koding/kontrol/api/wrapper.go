package main

import (
	"fmt"
	"github.com/streadway/amqp"
	"koding/tools/amqputil"
	"koding/tools/config"
)

const exchangeName = "infoExchange"
const channelName = "webApi"
const bindingKey = "output.webapi"

type AmqpWrapper struct {
	channel *amqp.Channel
	input   <-chan amqp.Delivery
}

func setupAmqp() (ext *AmqpWrapper) {
	user := config.Current.Kontrold.RabbitMq.Login
	password := config.Current.Kontrold.RabbitMq.Password
	host := config.Current.Kontrold.RabbitMq.Host
	port := config.Current.Kontrold.RabbitMq.Port

	connection := amqputil.CreateAmqpConnection(user, password, host, port)
	channel := amqputil.CreateChannel(connection)
	_, err := channel.QueueDeclare(channelName, false, true, false, false, nil)
	if err != nil {
		fmt.Println(err)
	}

	err = channel.QueueBind(channelName, bindingKey, exchangeName, false, nil)
	if err != nil {
		fmt.Println(err)
	}

	input, err := channel.Consume(channelName, "", true, true, false, false, nil)
	if err != nil {
		fmt.Println(err)
	}

	ext = &AmqpWrapper{channel, input}

	return
}

func (self *AmqpWrapper) Tell(cmd []byte) {
	//wm := WorkerMessage{"status", "all", "result"}
	//mes := Message{"worker", wm, "secret-worker-uuid", "senthils-MacBook-Pro.local-915", 0, 4, 1}
	//data, err := json.Marshal(mes)

	//data, err := json.Marshal(cmd)
	//if err != nil {
	//fmt.Println(data)
	//}

	msg := buildMessage(cmd)
	self.channel.Publish(exchangeName, "input.webapi", false, false, msg)
}

func (self *AmqpWrapper) Listen() <-chan amqp.Delivery {
	return self.input
}

func buildMessage(cmd []byte) (msg amqp.Publishing) {
	msg = amqp.Publishing{
		Headers:         amqp.Table{},
		ContentType:     "text/plain",
		ContentEncoding: "",
		Body:            cmd,
		DeliveryMode:    1, // 1=non-persistent, 2=persistent
		Priority:        0, // 0-9
	}

	return
}
