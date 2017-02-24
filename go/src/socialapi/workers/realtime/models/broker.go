package models

import (
	"encoding/json"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

type Broker struct {
	rmqConn *amqp.Connection
	log     logging.Logger
}

func NewBroker(rmq *rabbitmq.RabbitMQ, log logging.Logger) *Broker {

	return &Broker{
		rmqConn: rmq.Conn(),
		log:     log,
	}
}

func (b *Broker) UpdateChannel(pm *PushMessage) error {
	// convert data into json message
	byteMessage, err := json.Marshal(pm.Body)
	if err != nil {
		return err
	}

	// get a new channel for publishing a message

	channel, err := b.rmqConn.Channel()
	if err != nil {
		return err
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
			return err
		}
	}

	return nil
}

func (b *Broker) NotifyUser(nm *NotificationMessage) error {
	channel, err := b.rmqConn.Channel()
	if err != nil {
		return err
	}
	defer channel.Close()

	byteNotification, err := json.Marshal(nm.Body)
	if err != nil {
		return err
	}

	return channel.Publish(
		"notification",
		nm.Account.Nick, // this is routing key
		false,
		false,
		amqp.Publishing{Body: byteNotification},
	)
}
