// This must be taken into a more general package. A similar
// file already exists in migrators/graphity/common package

package main

import (
  "encoding/json"
  "github.com/streadway/amqp"
  . "koding/db/models"
  "koding/tools/amqputil"
  "log"
)

var (
  GRAPHITY_CHANNEL *amqp.Channel
)

func init() {
  connectToRabbitMQ()
  log.Println("Connected to rabbit")
}

func connectToRabbitMQ() {
  var err error

  conn := amqputil.CreateConnection("graphityRelationship")
  GRAPHITY_CHANNEL, err = conn.Channel()
  conn.Channel()
  if err != nil {
    panic(err)
  }
}

func CreateGraphRelationship(relationship Relationship) {
  updateRelationship(relationship, "RelationshipSaved")
}

func RemoveGraphRelationship(relationship Relationship) {
  updateRelationship(relationship, "RelationshipRemoved")
}

func updateRelationship(relationship Relationship, event string) {
  data := make([]Relationship, 1)
  data[0] = relationship
  eventData := map[string]interface{}{"event": event, "payload": data}

  neoMessage, err := json.Marshal(eventData)

  if err != nil {
    log.Println("unmarshall error")
    return
  }

  GRAPHITY_CHANNEL.Publish(
    "graphFeederExchange", // exchange name
    "",    // key
    false, // mandatory
    false, // immediate
    amqp.Publishing{
      Body: neoMessage,
    },
  )
}
