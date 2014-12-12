package models

import (
	"encoding/json"
	"fmt"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

type Broker struct {
	rmqConn *amqp.Connection
	log     logging.Logger
}

func NewBroker(rmq *rabbitmq.RabbitMQ, log logging.Logger) (*Broker, error) {
	rmqConn, err := rmq.Connect("NewGatekeeperBroker")
	if err != nil {
		return nil, err
	}

	return &Broker{
		rmqConn: rmqConn.Conn(),
		log:     log,
	}, nil
}

func (b *Broker) Authenticate(req *ChannelRequest) error {
	return nil
}

func (b *Broker) Push(pm *PushMessage) {
	//convert data into json message
	byteMessage, err := json.Marshal(pm.Body)
	if err != nil {
		b.log.Error("Could not marshal push message: %s", err)
		return
	}

	// get a new channel for publishing a message

	channel, err := b.rmqConn.Channel()
	if err != nil {
		b.log.Error("Could not get channel: %s", err)
		return
	}
	// do not forget to close the channel
	defer channel.Close()

	for _, secretName := range pm.Channel.SecretNames {
		routingKey := "socialapi.channelsecret." + secretName + "." + pm.EventName
		if err := channel.Publish(
			"broker",   // exchange name
			routingKey, // routing key
			false,      // mandatory
			false,      // immediate
			amqp.Publishing{Body: byteMessage}, // message
		); err != nil {
			b.log.Error("Could not publish message: %s", err)
			return
		}
	}
}

func (b *Broker) UpdateInstance(um *UpdateInstanceMessage) {
	channel, err := b.rmqConn.Channel()
	if err != nil {
		b.log.Error("Could not get channel: %s", err)
		return
	}
	defer channel.Close()

	routingKey := "oid." + um.Token + ".event." + um.EventName
	updateMessage, err := json.Marshal(um.Body)
	if err != nil {
		b.log.Error("Could not marshal update instance message: %s", err)
		return
	}

	updateArr := make([]string, 1)
	if um.EventName == "updateInstance" {
		updateArr[0] = fmt.Sprintf("{\"$set\":%s}", string(updateMessage))
	} else {
		updateArr[0] = string(updateMessage)
	}

	msg, err := json.Marshal(updateArr)
	if err != nil {
		b.log.Error("Could not marshal update instance array: %s", err)
		return
	}

	b.log.Debug(
		"Sending Instance Event Id:%s Message:%s EventName:%s",
		um.Token,
		updateMessage,
		um.EventName,
	)

	if err := channel.Publish(
		"updateInstances", // exchange name
		routingKey,        // routing key
		false,             // mandatory
		false,             // immediate
		amqp.Publishing{Body: msg}, // message
	); err != nil {
		b.log.Error("Could not publish update instance message: %s", err)
	}
}

func (b *Broker) NotifyUser(nm *NotificationMessage) {
	channel, err := b.rmqConn.Channel()
	if err != nil {
		b.log.Error("Could not get channel: %s", err)
		return
	}
	defer channel.Close()

	byteNotification, err := json.Marshal(nm.Body)
	if err != nil {
		b.log.Error("Could not marshal notification data: %s", err)
		return
	}

	if err := channel.Publish(
		"notification",
		nm.Nickname, // this is routing key
		false,
		false,
		amqp.Publishing{Body: byteNotification},
	); err != nil {
		b.log.Error("Could not publish notification message: %s", err)
	}
}
