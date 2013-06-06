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
	RoutingKey string `bson:"routingKey"`
	To         time.Time
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
	for {
		select {
		case err = <-errors:
			log.Printf("Handled an error: %v", err)
		}
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

		// TODO: this date is nil, probably because of a bug in streadway/amqp
		//t := d.Timestamp

		t := time.Now() // temporary workaround

		message := Message{from, d.RoutingKey, string(d.Body), Meta{t, t}}

		info, err := messages.Upsert(bson.M{"_id": nil}, message)
		if err != nil {
			done <- err
			continue
		}

		sliceKey := d.RoutingKey[:strings.LastIndex(d.RoutingKey, ".")]

		slice := ConversationSlice{sliceKey, t}

		sliceInfo, err := conversationSlices.
			Upsert(bson.M{"routingKey": sliceKey}, bson.M{"$set": slice})

		if err != nil {
			done <- err
			continue
		}

		if sliceInfo.UpsertedId != nil {
			if err := conversationSlices.Update(
				bson.M{"_id": sliceInfo.UpsertedId},
				bson.M{"$set": bson.M{"from": t}},
			); err != nil {
				done <- err
			}
		}

		m := bson.M{"event": "NewMessage", "payload": bson.M{
			"sourceId": sliceInfo.UpsertedId,
			"targetId": info.UpsertedId,
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
