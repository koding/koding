package main

import (
	"encoding/json"
	"github.com/streadway/amqp"
	"koding/databases/mongo"
	"koding/tools/amqputil"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
	"strings"
	"time"
)

type Meta struct {
	CreatedAt  time.Time `bson:"createdAt"`
	ModifiedAt time.Time `bson:"modifiedAt"`
}

type Message struct {
	From       string
	RoutingKey string `bson:"routingKey"`
	Body       string
	Meta       Meta
}

type ConversationSlice struct {
	From time.Time
	To   time.Time
	Id   bson.ObjectId `bson:"_id"`
}

func main() {
	conn := amqputil.CreateConnection("persistence")

	startPersisting(conn)
}

func startPersisting(conn *amqp.Connection) {

	amqpChannel, err := conn.Channel()
	if err != nil {
		panic(err)
	}

	if err := amqpChannel.ExchangeDeclare(
		"chat-hose", // exchange name
		"fanout",    // kind
		false,       // durable
		false,       // auto delete
		false,       // internal
		false,       // no wait
		nil,         // arguments
	); err != nil {
		panic(err)
	}

	if err := amqpChannel.ExchangeDeclare(
		"broker", // exchange name
		"topic",  // kind
		false,    // durable
		false,    // auto delete
		false,    // internal
		false,    // no wait
		nil,      // arguments
	); err != nil {
		panic(err)
	}

	if err := amqpChannel.ExchangeBind(
		"broker",    // destination
		"",          // key
		"chat-hose", // source
		false,       // no wait
		nil,         // arguments
	); err != nil {
		panic(err)
	}

	if _, err := amqpChannel.QueueDeclare(
		"persistence", // queue name
		false,         // durable
		true,          // autodelete
		true,          // exclusive
		false,         // no wait
		nil,           // arguments
	); err != nil {
		panic(err)
	}

	if err := amqpChannel.QueueBind(
		"persistence", // queue name
		"",            // key
		"chat-hose",   // exchange name
		false,         // no wait
		nil,           // arguments
	); err != nil {
		panic(err)
	}

	deliveries, err := amqpChannel.Consume(
		"persistence", // queue name
		"",            // ctag
		false,         // no-ack
		false,         // exlusive
		false,         // no local
		false,         // no wait
		nil,           // arguments
	)
	if err != nil {
		panic(err)
	}

	errors := make(chan error)

	go persistMessages(
		amqpChannel,
		deliveries,
		mongo.GetCollection("jMessages"),
		mongo.GetCollection("jConversationSlices"),
		errors,
	)

	select {
	case errors <- err:
		log.Printf("Handled an error: %v", err)
	}
}

func persistMessages(
	amqpChannel *amqp.Channel,
	deliveries <-chan amqp.Delivery,
	messages *mgo.Collection,
	conversationSlices *mgo.Collection,
	done chan error,
) {

	for d := range deliveries {

		from := d.RoutingKey[strings.LastIndex(d.RoutingKey, ".")+1:]

		t := d.Timestamp

		message := Message{from, d.RoutingKey, string(d.Body), Meta{t, t}}

		info, err := messages.Upsert(bson.M{"_id": nil}, message)
		if err != nil {
			done <- err
			continue
		}

		slice := new(ConversationSlice)
		if err := conversationSlices.
			Find(bson.M{"routingKey": d.RoutingKey}).
			One(&slice); err != nil {
			done <- err
			continue
		}

		m := bson.M{"event": "NewMessage", "payload": bson.M{
			"source": slice.Id,
			"target": info.UpsertedId,
		}}

		neoMessage, err := json.Marshal(m)
		if err != nil {
			done <- err
			continue
		}

		amqpChannel.Publish(
			"neo4jFeederExchange", // exchange name
			"",                    // key
			false,                 // mandatory
			false,                 // immediate
			amqp.Publishing{
				Body: neoMessage,
			},
		)
	}
}
