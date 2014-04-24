package main

// this file is created by Aybars, but i am committing it :)

import (
	"encoding/json"
	"flag"
	"fmt"
	"koding/databases/elasticsearch"
	"koding/tools/config"
	"os"
	"strconv"
	"time"
	"github.com/koding/logging"

	"github.com/koding/rabbitmq"
	"github.com/mattbaird/elastigo/api"
	"github.com/mattbaird/elastigo/indices"
	"github.com/streadway/amqp"
	"labix.org/v2/mgo/bson"
)

var (
	EXCHANGE_NAME     = "graphFeederExchange"
	TIME_FORMAT       = "2006-01-02T15:04:05.000Z"
	WORKER_QUEUE_NAME string
	flagDebug         = flag.Bool("d", false, "Debug mode")
	configProfile     = flag.String("c", "", "Configuration profile from file")
	log               logging.Logger
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

func main() {
	flag.Parse()
	if *configProfile == "" {
		fmt.Println("Please define config file with -c")
		return
	}

	conf := config.MustConfig(*configProfile)

	log = logging.NewLogger("ElasticsearchFeeder")
	logHandler := logging.NewWriterHandler(os.Stderr)
	logHandler.Colorize = true
	log.SetHandler(logHandler)

	if *flagDebug {
		log.SetLevel(logging.DEBUG)
		logHandler.SetLevel(logging.DEBUG)
	}

	// this is for ElasticSearch
	api.Domain = conf.ElasticSearch.Host
	api.Port = strconv.Itoa(conf.ElasticSearch.Port)

	WORKER_QUEUE_NAME = conf.ElasticSearch.Queue
	// ping before we start
	_, err := indices.Status(true)
	if err != nil {
		fmt.Println("cant connect to elasticsearch server, cowardly refusing to start")
		fmt.Println(err)
		return
	}
	// everything's ok lets run
	startConsuming(conf)
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

var handler = func(msg amqp.Delivery) {
	message, err := jsonDecode(string(msg.Body))
	if err != nil {
		fmt.Println("Wrong message format", err, message)
		msg.Ack(false)
		return
	}

	if len(message.Payload) < 1 {
		fmt.Println("Wrong message format; payload should be an Array", message)
		msg.Ack(false)
		return
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
		msg.Ack(false)
	}
}

func startConsuming(conf *config.Config) {
	exchange := rabbitmq.Exchange{
		Name:    EXCHANGE_NAME,
		Type:    "fanout",
		Durable: true,
	}

	queue := rabbitmq.Queue{
		Name:    WORKER_QUEUE_NAME,
		Durable: true,
	}

	binding := rabbitmq.BindingOptions{}

	consumerOptions := rabbitmq.ConsumerOptions{
		Tag: "ElasticSearchFeeder",
	}

	rmqConf := &rabbitmq.Config{
		Host:     conf.Mq.Host,
		Port:     conf.Mq.Port,
		Username: conf.Mq.ComponentUser,
		Password: conf.Mq.Password,
		Vhost:    conf.Mq.Vhost,
	}
	r := rabbitmq.New(rmqConf, log)
	consumer, err := r.NewConsumer(exchange, queue, binding, consumerOptions)
	if err != nil {
		fmt.Print(err)
	}
	defer consumer.Shutdown()

	fmt.Println("Elasticsearch Feeder worker started")
	consumer.RegisterSignalHandler()
	consumer.Consume(handler)

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
