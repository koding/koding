// This must be taken into a more general package. A similar
// file already exists in migrators/graphity/common package

package topicmodifier

import (
	. "koding/db/models"

	"github.com/koding/rabbitmq"
)

var (
	GraphPublisher *rabbitmq.Producer
)

func initGraphPublisher() {
	options := &PublisherConfig{
		ExchangeName: "graphFeederExchange",
		Tag:          "graphityRelationship",
		RoutingKey:   "",
	}
	GraphPublisher = createPublisher(options)
}

func CreateGraphRelationship(relationship *Relationship) error {
	return updateRelationship(relationship, "RelationshipSaved")
}

func RemoveGraphRelationship(relationship *Relationship) error {
	return updateRelationship(relationship, "RelationshipRemoved")
}

func updateRelationship(relationship *Relationship, event string) error {
	data := make([]Relationship, 1)
	data[0] = *relationship
	eventData := map[string]interface{}{"event": event, "payload": data}

	return publish(GraphPublisher, eventData)
}
