package main

import (
	"encoding/json"
	"fmt"
	"github.com/streadway/amqp"
	"koding/databases/mongo"
	"koding/databases/neo4j"
	"koding/tools/amqputil"
	"labix.org/v2/mgo/bson"
	"strings"
)

var (
	EXCHANGE_NAME     = "neo4jFeederExchange"
	WORKER_QUEUE_NAME = "neo4jFeederWorkerQueue"
)

type Consumer struct {
	conn    *amqp.Connection
	channel *amqp.Channel
}

type Message struct {
	Event   string                   `json:"event"`
	Payload []map[string]interface{} `json:"payload"`
}

func main() {
	fmt.Println("Neo4J Feeder worker started")
	startConsuming()
	//looooop forever
	select {}
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

	err := c.channel.ExchangeDeclare(EXCHANGE_NAME, "fanout", false, false, false, false, nil)
	if err != nil {
		fmt.Println("exchange.declare: %s", err)
		panic(err)
	}

	//name, durable, autoDelete, exclusive, noWait, args Table
	if _, err := c.channel.QueueDeclare(WORKER_QUEUE_NAME, true, false, false, false, nil); err != nil {
		fmt.Println("queue.declare: %s", err)
		panic(err)
	}

	if err := c.channel.QueueBind(WORKER_QUEUE_NAME, "" /* binding key */, EXCHANGE_NAME, false, nil); err != nil {
		fmt.Println("queue.bind: %s", err)
		panic(err)
	}

	//(queue, consumer string, autoAck, exclusive, noLocal, noWait bool, args Table) (<-chan Delivery, error) {
	relationshipEvent, err := c.channel.Consume(WORKER_QUEUE_NAME, "neo4jFeeding", true, false, false, false, nil)
	if err != nil {
		fmt.Println("basic.consume: %s", err)
		panic(err)
	}

	go func() {
		for msg := range relationshipEvent {
			body := fmt.Sprintf("%s", msg.Body)

			message, err := jsonDecode(body)
			if err != nil {
				fmt.Println("Wrong message format", err, body)

				continue
			}

			if len(message.Payload) < 1 {
				fmt.Println("Wrong message format; payload should be an Array", message)

				continue
			}
			data := message.Payload[0]

			fmt.Println(message.Event)
			if message.Event == "RelationshipSaved" {
				createNode(data)
			} else if message.Event == "RelationshipRemoved" {
				deleteRelationship(data)
			} else if message.Event == "updateInstance" {
				updateNode(data)
			} else if message.Event == "RemovedFromCollection" {
				deleteNode(data)
			}
		}
	}()
}

func checkIfEligible(sourceName, targetName string) bool {

	notAllowedNames := []string{
		"CStatusActivity",
		"CFolloweeBucketActivity",
		"CFollowerBucketActivity",
		"CCodeSnipActivity",
		"CDiscussionActivity",
		"CReplieeBucketActivity",
		"CReplierBucketActivity",
		"CBlogPostActivity",
		"CNewMemberBucketActivity",
		"CTutorialActivity",
		"CLikeeBucketActivity",
		"CLikerBucketActivity",
		"CInstalleeBucketActivity",
		"CInstallerBucketActivity",
		"CActivity",
		"CRunnableActivity",
		"JAppStorage",
		"JFeed",
	}
	notAllowedSuffixes := []string{
		"Bucket",
		"BucketActivity",
	}

	for _, name := range notAllowedNames {
		if name == sourceName {
			fmt.Println("not eligible " + sourceName)
			return false
		}

		if name == targetName {
			fmt.Println("not eligible " + targetName)
			return false
		}
	}

	for _, name := range notAllowedSuffixes {

		if strings.HasSuffix(sourceName, name) {
			fmt.Println("not eligible " + sourceName)
			return false
		}

		if strings.HasSuffix(targetName, name) {
			fmt.Println("not eligible " + targetName)
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

	if !checkIfEligible(sourceName, targetName) {
		return
	}

	sourceNode := neo4j.CreateUniqueNode(sourceId, sourceName)

	sourceContent, err := mongo.FetchContent(bson.ObjectIdHex(sourceId), sourceName)
	if err != nil {
		fmt.Println(err)
	} else {
		neo4j.UpdateNode(sourceId, sourceContent)
	}

	targetNode := neo4j.CreateUniqueNode(targetId, targetName)
	targetContent, err := mongo.FetchContent(bson.ObjectIdHex(targetId), targetName)
	if err != nil {
		fmt.Println(err)
	} else {
		neo4j.UpdateNode(targetId, targetContent)
	}

	source := fmt.Sprintf("%s", sourceNode["create_relationship"])
	target := fmt.Sprintf("%s", targetNode["self"])

	if _, ok := data["as"]; !ok {
		return
	}
	as := fmt.Sprintf("%s", data["as"])

	if _, ok := data["_id"]; !ok {
		return
	}
	id := fmt.Sprintf("%s", data["_id"])

	if bson.IsObjectIdHex(id) {
		createdAt := bson.ObjectIdHex(id).Time().UTC()
		relationshipData := fmt.Sprintf(`{"createdAt" : "%s", "createdAtEpoch" : %d }`, createdAt.Format("2006-01-02T15:04:05.000Z"), createdAt.Unix())

		neo4j.CreateRelationshipWithData(as, source, target, relationshipData)
	} else {
		fmt.Println("id is not in correct format")
	}

}

func deleteNode(data map[string]interface{}) {

	if _, ok := data["_id"]; !ok {
		return
	}
	id := fmt.Sprintf("%s", data["_id"])
	neo4j.DeleteNode(id)
}

func deleteRelationship(data map[string]interface{}) {
	sourceId := fmt.Sprintf("%s", data["sourceId"])
	targetId := fmt.Sprintf("%s", data["targetId"])
	as := fmt.Sprintf("%s", data["as"])

	result := neo4j.DeleteRelationship(sourceId, targetId, as)
	if result {
		fmt.Println("Relationship deleted")
	} else {
		fmt.Println("Relationship couldnt be deleted")
	}
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

	if !checkIfEligible(sourceName, "") {
		return
	}

	neo4j.CreateUniqueNode(sourceId, sourceName)
	sourceContent, err := mongo.FetchContent(bson.ObjectIdHex(sourceId), sourceName)
	if err != nil {
		fmt.Println(err)
	} else {
		neo4j.UpdateNode(sourceId, sourceContent)
	}
}
