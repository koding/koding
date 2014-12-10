package models

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"socialapi/config"
	"socialapi/workers/common/handler"

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
	// fetch these secret names from socialapi
	resp, err := fetchSecretNamesById(pm.ChannelId)
	if err != nil {
		b.log.Error("Could not fetch secret names: %s", err)
		return
	}

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

	for _, secretName := range resp.SecretNames {
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
}

func fetchSecretNamesById(channelId int64) (*ChannelResponse, error) {
	request := &handler.Request{
		Type:     handler.GetRequest,
		Endpoint: fmt.Sprintf("%s/channel/%d/secretnames", config.MustGet().ProxyURL, channelId),
	}

	resp, err := handler.MakeRequest(request)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf(resp.Status)
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	channelResponse := new(ChannelResponse)
	err = json.Unmarshal(body, channelResponse)
	if err != nil {
		return nil, err
	}

	return channelResponse, nil
}
