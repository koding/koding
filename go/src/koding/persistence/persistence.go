package main

import (
	"encoding/json"
	"flag"
	"koding/db/mongodb"
	"koding/tools/amqputil"
	"koding/tools/config"
	"log"
	"strings"
	"time"

	"github.com/streadway/amqp"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
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

func init() {
	f := flag.NewFlagSet("persistence", flag.ContinueOnError)
	f.StringVar(&configProfile, "c", "", "Configuration profile from file")
}

var mongo *mongodb.MongoDB
var configProfile string

func main() {
	flag.Parse()
	conf := config.MustConfig(configProfile)
	mongo = mongodb.NewMongoDB(conf.Mongo)

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
		true,          // auto-ack
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
	done chan error,
) {

	var err error
	for d := range deliveries {

		from := d.RoutingKey[strings.LastIndex(d.RoutingKey, ".")+1:]

		// TODO: this date is nil, probably because of a bug in streadway/amqp
		//t := d.Timestamp

		t := time.Now() // temporary workaround

		message := Message{from, d.RoutingKey, string(d.Body), Meta{t, t}}

		info := new(mgo.ChangeInfo)
		err := mongo.Run("jMessages", func(c *mgo.Collection) error {
			info, err = c.Upsert(bson.M{"_id": nil}, message)
			return err
		})

		if err != nil {
			done <- err
			continue
		}

		sliceKey := d.RoutingKey[:strings.LastIndex(d.RoutingKey, ".")]

		slice := ConversationSlice{
			RoutingKey: sliceKey,
			To:         t,
		}

		sliceInfo := new(mgo.ChangeInfo)
		err = mongo.Run("jMessages", func(c *mgo.Collection) error {
			sliceInfo, err = c.Upsert(bson.M{"routingKey": sliceKey}, bson.M{"$set": slice})
			return err
		})

		if err != nil {
			done <- err
			continue
		}

		if sliceInfo.UpsertedId != nil {
			err := mongo.Run("jConversationSlices", func(c *mgo.Collection) error {
				return c.Update(
					bson.M{"_id": sliceInfo.UpsertedId},
					bson.M{"$set": bson.M{"from": t}})
			})

			if err != nil {
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
			"graphFeederExchange", // exchange name
			"",    // key
			false, // mandatory
			false, // immediate
			amqp.Publishing{
				DeliveryMode: amqp.Persistent,
				Body:         neoMessage,
			},
		)
	}
}
