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

func (b *Broker) UpdateInstance(um *UpdateInstanceMessage) error {
	channel, err := b.rmqConn.Channel()
	if err != nil {
		return err
	}
	defer channel.Close()

	routingKey := "oid." + um.Token + ".event." + um.EventName
	updateMessage, err := json.Marshal(um.Body)
	if err != nil {
		return err
	}

	updateArr := make([]string, 1)
	if um.EventName == "updateInstance" {
		updateArr[0] = fmt.Sprintf("{\"$set\":%s}", string(updateMessage))
	} else {
		updateArr[0] = string(updateMessage)
	}

	msg, err := json.Marshal(updateArr)
	if err != nil {
		return err
	}

	b.log.Debug(
		"Sending Instance Event Id:%s Message:%s EventName:%s",
		um.Token,
		updateMessage,
		um.EventName,
	)

	return channel.Publish(
		"updateInstances", // exchange name
		routingKey,        // routing key
		false,             // mandatory
		false,             // immediate
		amqp.Publishing{Body: msg}, // message
	)
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
		nm.Account.Nickname, // this is routing key
		false,
		false,
		amqp.Publishing{Body: byteNotification},
	)
}
