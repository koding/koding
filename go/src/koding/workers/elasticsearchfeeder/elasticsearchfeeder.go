package main

// this file is created by Aybars, but i am committing it :)

import (
	"encoding/json"
	"fmt"
	"github.com/mattbaird/elastigo/api"
	"github.com/mattbaird/elastigo/indices"
	"github.com/streadway/amqp"
	"koding/databases/elasticsearch"
	"koding/tools/amqputil"
	"koding/tools/config"
	"labix.org/v2/mgo/bson"
	"strconv"
	"time"
)

var (
	EXCHANGE_NAME     = "graphFeederExchange"
	WORKER_QUEUE_NAME = config.Current.ElasticSearch.Queue
	TIME_FORMAT       = "2006-01-02T15:04:05.000Z"
)

type Consumer struct {
	conn    *amqp.Connection
	channel *amqp.Channel
}

type Message struct {
	Event   string                   `json:"event"`
	Payload []map[string]interface{} `json:"payload"`
}

type Action func(*elasticsearch.Controller, map[string]interface{}) bool

var RoutingTable = map[string]Action{
	"RelationshipSaved":   (*elasticsearch.Controller).ActionCreateNode,
	"RelationshipRemoved": (*elasticsearch.Controller).ActionDeleteRelationship,
	"updateInstance":      (*elasticsearch.Controller).ActionUpdateNode,
	"deleteNode":          (*elasticsearch.Controller).ActionDeleteNode,
}

//here, mapping of decoded json
func jsonDecode(data string) (*Message, error) {
	source := &Message{}
	err := json.Unmarshal([]byte(data), &source)
	if err != nil {
		return source, err
	}

	return source, nil
}

func startConsuming() {
	c := &Consumer{}
	c.conn = amqputil.CreateConnection("elasticSearchFeederWorkerQueue")
	c.channel = amqputil.CreateChannel(c.conn)

	err := c.channel.ExchangeDeclare(EXCHANGE_NAME, "fanout", true, false, false, false, nil)
	if err != nil {
		fmt.Println("exchange.declare: %s", err)
		panic(err)
	}

	//name, durable, autoDelete, exclusive, noWait, args Table
	if _, err := c.channel.QueueDeclare(WORKER_QUEUE_NAME, true, false, false, false, nil); err != nil {
		fmt.Println("queue.declare: %s", err)
		panic(err)
	}

	if err := c.channel.QueueBind(WORKER_QUEUE_NAME, "", EXCHANGE_NAME, false, nil); err != nil {
		fmt.Println("queue.bind: %s", err)
		panic(err)
	}

	//(queue, consumer string, autoAck, exclusive, noLocal, noWait bool, args Table) (<-chan Delivery, error) {
	relationshipEvent, err := c.channel.Consume(WORKER_QUEUE_NAME, WORKER_QUEUE_NAME, false, false, false, false, nil)
	if err != nil {
		fmt.Println("basic.consume: %s", err)
		panic(err)
	}

	fmt.Println("Elasticsearch Feeder worker started")

	for msg := range relationshipEvent {
		message, err := jsonDecode(string(msg.Body))
		if err != nil {
			fmt.Println("Wrong message format", err, message)
			continue
		}

		if len(message.Payload) < 1 {
			fmt.Println("Wrong message format; payload should be an Array", message)
			continue
		}
		data := message.Payload[0]

		controller := elasticsearch.Controller{}

		actionFn := RoutingTable[message.Event]
		if actionFn != nil {
			if actionFn(&controller, data) {
				// always use late ack
				msg.Ack(false)
			}
		} else {
			fmt.Println("Unknown event received ", message.Event)
		}
	}
}

func getCreatedAtDate(data map[string]interface{}) time.Time {

	if _, ok := data["timestamp"]; ok {
		t, err := time.Parse(TIME_FORMAT, data["timestamp"].(string))
		// if error doesnt exists, return createdAt
		if err == nil {
			return t.UTC()
		}
	}

	id := fmt.Sprintf("%s", data["_id"])
	if bson.IsObjectIdHex(id) {
		return bson.ObjectIdHex(id).Time().UTC()
	}

	fmt.Print("Couldnt determine the createdAt time, returning Now() as createdAt")
	return time.Now().UTC()
}

func main() {
	// this is for ElasticSearch
	api.Domain = config.Current.ElasticSearch.Host
	api.Port = strconv.Itoa(config.Current.ElasticSearch.Port)

	// ping before we start
	_, err := indices.Status(true)
	if err != nil {
		fmt.Println("cant connect to elasticsearch server, cowardly refusing to start")
		fmt.Println(err)
		return
	}
	// everything's ok lets run
	startConsuming()
}
