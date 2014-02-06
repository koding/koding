package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"koding/databases/neo4j"
	"koding/db/mongodb"
	"koding/tools/amqputil"
	"koding/tools/config"
	"koding/tools/logger"
	"koding/tools/statsd"
	"koding/workers/neo4jfeeder/mongohelper"
	"os"
	"strings"
	"time"

	"github.com/streadway/amqp"
	"labix.org/v2/mgo/bson"
)

var (
	EXCHANGE_NAME     = "graphFeederExchange"
	WORKER_QUEUE_NAME = "graphFeederWorkerQueue"
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

func init() {
	flagSet = flag.NewFlagSet("neo4jfeeder", flag.ContinueOnError)
	flagSet.StringVar(&configProfile, "c", "", "Configuration profile from file")
}

var (
	log           = logger.New("neo4jfeeder")
	mongo         *mongodb.MongoDB
	configProfile string
	flagSet       *flag.FlagSet
)

func main() {
	flagSet.Parse(os.Args)
	if configProfile == "" {
		log.Fatal("Please define config file with -c")
	}

	amqputil.SetupAMQP(configProfile)
	conf := config.MustConfig(configProfile)
	mongo = mongodb.NewMongoDB(conf.Mongo)
	mongohelper.MongoHelperInit(conf.Mongo)

	statsd.SetAppName("neo4jFeeder")
	startConsuming()
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
	c := &Consumer{
		conn:    nil,
		channel: nil,
	}

	c.conn = amqputil.CreateConnection("neo4jFeeding")
	c.channel = amqputil.CreateChannel(c.conn)
	// exchangeName, ExchangeType, durable, autoDelete, internal, noWait, args
	err := c.channel.ExchangeDeclare(EXCHANGE_NAME, "fanout", true, false, false, false, nil)
	if err != nil {
		log.Panic("exchange.declare: %s", err)
	}

	//name, durable, autoDelete, exclusive, noWait, args Table
	if _, err := c.channel.QueueDeclare(WORKER_QUEUE_NAME, true, false, false, false, nil); err != nil {
		log.Panic("queue.declare: %s", err)
	}

	if err := c.channel.QueueBind(WORKER_QUEUE_NAME, "" /* binding key */, EXCHANGE_NAME, false, nil); err != nil {
		log.Panic("queue.bind: %s", err)
	}

	//(queue, consumer string, autoAck, exclusive, noLocal, noWait bool, args Table) (<-chan Delivery, error) {
	relationshipEvent, err := c.channel.Consume(WORKER_QUEUE_NAME, "neo4jFeeding", false, false, false, false, nil)
	if err != nil {
		log.Panic("basic.consume: %s", err)
	}

	log.Notice("Neo4J Feeder worker started")

	for msg := range relationshipEvent {
		body := fmt.Sprintf("%s", msg.Body)

		message, err := jsonDecode(body)
		if err != nil {
			log.Error("Wrong message format err: %v, body: %v", err, body)
			msg.Ack(true)
			continue
		}

		if len(message.Payload) < 1 {
			log.Error("Wrong message format; payload should be an Array message %v", message)
			msg.Ack(true)
			continue
		}
		data := message.Payload[0]

		log.Debug("%v %v", message.Event, data)

		if message.Event == "RelationshipSaved" {
			createNode(data)
		} else if message.Event == "RelationshipRemoved" {
			deleteRelationship(data)
		} else if message.Event == "updateInstance" {
			updateNode(data)
		} else if message.Event == "RemovedFromCollection" {
			deleteNode(data)
		} else {
			log.Debug("No method found for event: %v", message.Event)
		}

		msg.Ack(true)
	}
}

func checkIfEligible(sourceName, targetName string) bool {
	notAllowedSuffixes := []string{
		"Bucket",
		"BucketActivity",
	}

	for _, name := range neo4j.NotAllowedNames {
		if name == sourceName {
			log.Debug("not eligible %v", sourceName)
			return false
		}

		if name == targetName {
			log.Debug("not eligible %v", targetName)
			return false
		}
	}

	for _, name := range notAllowedSuffixes {
		if strings.HasSuffix(sourceName, name) {
			log.Debug("not eligible %v", sourceName)
			return false
		}

		if strings.HasSuffix(targetName, name) {
			log.Debug("not eligible %v", targetName)
			return false
		}
	}

	return true
}

func createNode(data map[string]interface{}) {
	sourceId := fmt.Sprintf("%s", data["sourceId"])
	sourceName := fmt.Sprintf("%s", data["sourceName"])

	targetId := fmt.Sprintf("%s", data["targetId"])
	targetName := fmt.Sprintf("%s", data["targetName"])

	if sourceId == "" || sourceName == "" || targetId == "" || targetName == "" {
		log.Error("createNode invalid data: %v", data)
		return
	}

	if !checkIfEligible(sourceName, targetName) {
		return
	}

	if checkForGuestGroup(sourceId, targetId) {
		return
	}

	sTimer := statsd.StartTimer("createNode")

	sourceContent, err := mongohelper.FetchContent(bson.ObjectIdHex(sourceId), sourceName)
	if err != nil {
		sTimer.Failed()
		log.Error("createNode sourceContent %v\nid: %v, name: %v, data:%v",
			err, sourceId, sourceName, data)

		return
	}
	sourceNode := neo4j.CreateUniqueNode(sourceId, sourceName)
	neo4j.UpdateNode(sourceId, sourceContent)

	targetContent, err := mongohelper.FetchContent(bson.ObjectIdHex(targetId), targetName)
	if err != nil {
		sTimer.Failed()
		log.Error("createNode targetContent %v\nid: %v, name: %v, data:%v",
			err, targetId, targetName, data)

		return
	}
	targetNode := neo4j.CreateUniqueNode(targetId, targetName)
	neo4j.UpdateNode(targetId, targetContent)

	source := fmt.Sprintf("%s", sourceNode["create_relationship"])
	target := fmt.Sprintf("%s", targetNode["self"])

	if _, ok := data["as"]; !ok {
		sTimer.Failed()
		log.Error("createNode as value is not set on this relationship. Discarding this record data: %v", data)

		return
	}
	as := fmt.Sprintf("%s", data["as"])

	if _, ok := data["_id"]; !ok {
		sTimer.Failed()
		log.Error("createNode id value is not set on this relationship. Discarding this record: %v", data)

		return
	}

	createdAt := getCreatedAtDate(data)
	relationshipData := fmt.Sprintf(`{"createdAt" : "%s", "createdAtEpoch" : %d }`, createdAt.Format(TIME_FORMAT), createdAt.Unix())
	neo4j.CreateRelationshipWithData(as, source, target, relationshipData)

	sTimer.Success()
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

	log.Warning("Couldnt determine the createdAt time, returning Now() as creatdAt")
	return time.Now().UTC()
}

func deleteNode(data map[string]interface{}) {
	sTimer := statsd.StartTimer("deleteNode")

	if _, ok := data["_id"]; !ok {
		sTimer.Failed()
		return
	}
	id := fmt.Sprintf("%s", data["_id"])
	neo4j.DeleteNode(id)

	sTimer.Success()
}

func deleteRelationship(data map[string]interface{}) {
	sourceId := fmt.Sprintf("%s", data["sourceId"])
	targetId := fmt.Sprintf("%s", data["targetId"])

	if sourceId == "" || targetId == "" {
		log.Error("deleteRelationship invalid data: %v", data)
		return
	}

	if checkForGuestGroup(sourceId, targetId) {
		return
	}

	sTimer := statsd.StartTimer("deleteRelationship")

	as := fmt.Sprintf("%s", data["as"])

	// we are not doing anything with result for now
	// do not pollute console
	neo4j.DeleteRelationship(sourceId, targetId, as)
	//result := neo4j.DeleteRelationship(sourceId, targetId, as)
	//if result {
	//	log.Info("Relationship deleted")
	//} else {
	//	log.Info("Relationship couldnt be deleted")
	//}

	sTimer.Success()
}

func updateNode(data map[string]interface{}) {
	if _, ok := data["bongo_"]; !ok {
		return
	}
	if _, ok := data["data"]; !ok {
		return
	}

	bongo := data["bongo_"].(map[string]interface{})
	obj := data["data"].(map[string]interface{})

	sourceId := fmt.Sprintf("%s", obj["_id"])
	sourceName := fmt.Sprintf("%s", bongo["constructorName"])

	if sourceId == "" || sourceName == "" {
		log.Error("updateNode invalid data: %v", data)
		return
	}

	if !checkIfEligible(sourceName, "") {
		return
	}

	if checkForGuestGroup(sourceId, sourceId) {
		return
	}

	sTimer := statsd.StartTimer("updateNode")

	sourceContent, err := mongohelper.FetchContent(bson.ObjectIdHex(sourceId), sourceName)
	if err != nil {
		sTimer.Failed()
		log.Error("updateNode sourceContent %v\ndata:%v", err, data)

		return
	}

	neo4j.CreateUniqueNode(sourceId, sourceName)
	neo4j.UpdateNode(sourceId, sourceContent)

	sTimer.Success()
}

func checkForGuestGroup(sourceId, targetId string) bool {

	// this is the guest group id of production database
	guestGroupId := "51f41f195f07655e560001c1"
	// this is the guest group in vagrant
	// guestGroupId = "51defdb73ed22b2905000023"

	if sourceId == guestGroupId || targetId == guestGroupId {
		return true
	}
	return false
}
