package main

import (
	"encoding/json"
	"fmt"
	"github.com/streadway/amqp"
	"koding/databases/neo4j"
	"koding/tools/amqputil"
	"log"
)

var (
	EXCHANGE_NAME     = "a-relationshipExchange"
	WORKER_QUEUE_NAME = "relationshipEventWorker"
)

type Consumer struct {
	conn    *amqp.Connection
	channel *amqp.Channel
}

type Message struct {
	Event string `json:"event"`
	Data []EventData
}

type EventData struct {
	SourceName string
	SourceId   string
	TargetName string
	TargetId   string
	As         string
}

func main() {
	log.Println("Neo4J Feeder worker started")
	startConsuming()
	//looooop forever
	select {}
}

//here, mapping of decoded json
func jsonDecode(data string) (*Message, error) {
	source := &Message{}
	err := json.Unmarshal([]byte(data), &source)
	if err != nil {
		fmt.Println("Marshalling error:", err)
		return source, err
	}

	return source, nil
}

func startConsuming() {

	c := &Consumer{
		conn:    nil,
		channel: nil,
	}

	c.conn = amqputil.CreateConnection("neo4jFeeding")
	c.channel = amqputil.CreateChannel(c.conn)

	err := c.channel.ExchangeDeclare(EXCHANGE_NAME, "fanout", false, false, false, false, nil)
	if err != nil {
		log.Fatal("exchange.declare: %s", err)
	}

	//name, durable, autoDelete, exclusive, noWait, args Table
	if _, err := c.channel.QueueDeclare(WORKER_QUEUE_NAME, true, false, false, false, nil); err != nil {
		log.Fatal("queue.declare: %s", err)
	}

	if err := c.channel.QueueBind(WORKER_QUEUE_NAME, "" /* binding key */, EXCHANGE_NAME, false, nil); err != nil {
		log.Fatal("queue.bind: %s", err)
	}

	//(queue, consumer string, autoAck, exclusive, noLocal, noWait bool, args Table) (<-chan Delivery, error) {
	relationshipEvent, err := c.channel.Consume("relationshipEventWorker", "neo4jFeeding", true, false, false, false, nil)
	if err != nil {
		log.Fatal("basic.consume: %s", err)
	}

	go func() {
		for msg := range relationshipEvent {
			body := fmt.Sprintf("%s", msg.Body)

			message, err := jsonDecode(body)
			if err != nil {
				log.Fatal(err)
			}
			//there will be only one array in data
			data := message.Data[0]
			fmt.Println(message.Event)
			if message.Event == "RelationshipSaved" {
				createNode(data)
			} else if message.Event == "RelationshipRemoved" {
				// deleteNode(data)
			}
		}
	}()
}

func createNode(data EventData) {

	sourceNode := neo4j.CreateUniqueNode(data.SourceId, data.SourceName)
	targetNode := neo4j.CreateUniqueNode(data.TargetId, data.TargetName)

	source := fmt.Sprintf("%s", sourceNode["create_relationship"])
	target := fmt.Sprintf("%s", targetNode["self"])
	neo4j.CreateRelationship(data.As, source, target)

}

func deleteNode(data EventData) {

	sourceNode := neo4j.DeleteNode(data.SourceId)
	fmt.Println(sourceNode)
	targetNode := neo4j.DeleteNode(data.TargetId)
	fmt.Println(targetNode)

}
