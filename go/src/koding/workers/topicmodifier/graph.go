// This must be taken into a more general package. A similar
// file already exists in migrators/graphity/common package

package main

import (
	"encoding/json"
	"github.com/streadway/amqp"
	. "koding/db/models"
	"koding/messaging/rabbitmq"
)

var (
	GRAPHITY_CHANNEL *amqp.Channel
	PUBLISHER        *rabbitmq.Producer
)

func init() {
	exchange := rabbitmq.Exchange{
		Name: "graphFeederExchange",
	}
	queue := rabbitmq.Queue{}
	publishingOptions := rabbitmq.PublishingOptions{
		Tag:        "graphityRelationship",
		RoutingKey: "",
	}
	// var err Error
	var err error
	PUBLISHER, err = rabbitmq.NewProducer(exchange, queue, publishingOptions)
	if err != nil {
		panic(err)
	}

	PUBLISHER.RegisterSignalHandler()
}

func CreateGraphRelationship(relationship *Relationship) {
	updateRelationship(relationship, "RelationshipSaved")
}

func RemoveGraphRelationship(relationship *Relationship) {
	updateRelationship(relationship, "RelationshipRemoved")
}

func updateRelationship(relationship *Relationship, event string) {
	data := make([]Relationship, 1)
	data[0] = *relationship
	eventData := map[string]interface{}{"event": event, "payload": data}

	neoMessage, err := json.Marshal(eventData)

	if err != nil {
		log.Error("unmarshall error")
		return
	}

	message := amqp.Publishing{
		Body: neoMessage,
	}

	PUBLISHER.NotifyReturn(func(message amqp.Return) {
		log.Info("%v", message)
	})

	err = PUBLISHER.Publish(message)
	if err != nil {
		log.Error(err.Error())
	}
}
