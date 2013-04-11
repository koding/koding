package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	// "koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
	"net/http"
	"strings"
	"time"
)

type Relationship struct {
	TargetId   bson.ObjectId `bson:"targetId,omitempty"`
	TargetName string        `bson:"targetName"`
	SourceId   bson.ObjectId `bson:"sourceId,omitempty"`
	SourceName string        `bson:"sourceName"`
	As         string
	Data       bson.Binary
	Timestamp  time.Time
}

var (

	// todo update this constants, here must be only config file related strings after config files updated  
	// BASE_URL         = config.Current.Neo4j.Url + config.Current.Neo4j.Port  // "http://localhost:7474"
	BASE_URL         = "http://localhost:7474"
	UNIQUE_NODE_PATH = "/db/data/index/node/koding?unique"
	INDEX_PATH       = "/db/data/index/node"
	// MONGO_CONN_STRING = config.Current.Mongo //"mongodb://dev:k9lc4G1k32nyD72@web-dev.in.koding.com:27017/koding_dev2_copy"
	MONGO_CONN_STRING = "mongodb://dev:k9lc4G1k32nyD72@web-dev.in.koding.com:27017/koding_dev2_copy"
)

// Gets URL and string data to be sent and makes POST request
// reads response body and returns as string
func sendRequest(url string, data string) string {
	//convert string into bytestream
	dataByte := strings.NewReader(data)

	//make post request
	req, err := http.Post(url, "application/json", dataByte)
	if err != nil {
		log.Fatal(err)
	}

	// read response body
	body, _ := ioutil.ReadAll(req.Body)

	defer req.Body.Close()

	return fmt.Sprintf("%s", body)
}

// This is a custom json string generator as http request body to neo4j
func getPostJsonData(id, name string) string {
	return fmt.Sprintf(`{ "key" : "id", "value" : "%s", "properties" : { "id" : "%s", "name" : "%s" } }`, id, id, name)
}

//here, mapping of decoded json
func jsonDecode(data string) (map[string]interface{}, error) {
	var source map[string]interface{}

	marshalErr := json.Unmarshal([]byte(data), &source)

	if marshalErr != nil {
		fmt.Println("Marshalling error:", marshalErr)
		return nil, marshalErr
	}

	return source, nil
}

// connect source and target with relationship's As property
func createRelationship(mongoRecord *Relationship, sourceNode, targetNode map[string]interface{}) map[string]interface{} {
	relationshipData := fmt.Sprintf(`{"to" : "%s", "type" : "%s" }`, targetNode["self"], mongoRecord.As)
	relRes := sendRequest(fmt.Sprintf("%s", sourceNode["create_relationship"]), relationshipData)

	relNode, err := jsonDecode(relRes)
	if err != nil {
		fmt.Println("Problem with relation response", relRes)
	}

	return relNode
}

// creates a unique node with given id and node name
func createUniqueNode(id string, name string) map[string]interface{} {
	url := BASE_URL + UNIQUE_NODE_PATH
	// url := "http://localhost:7474/db/data/index/node/koding?unique"

	postData := getPostJsonData(id, name)

	response := sendRequest(url, postData)

	nodeData, err := jsonDecode(response)

	if err != nil {
		fmt.Println("Problem with response", response)
	}

	return nodeData
}

// creates a unique tree head node to hold all nodes
// it is called once during runtime while initializing
func createUniqueIndex() {
	//create unique index
	url := BASE_URL + INDEX_PATH

	bd := sendRequest(url, `{"name":"koding"}`)

	fmt.Println("Created unique index for data", bd)
}

func main() {
	// connnect to mongo
	conn, err := mgo.Dial(MONGO_CONN_STRING)

	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	conn.SetMode(mgo.Monotonic, true)

	createUniqueIndex()

	relationshipColl := conn.DB("koding_dev2_copy").C("relationships")

	var result Relationship
	iter := relationshipColl.Find(nil).Iter()

	//iterate over results
	for iter.Next(&result) {
		var sourceId string = fmt.Sprintf("%x", string(result.SourceId))
		var targetId string = fmt.Sprintf("%x", string(result.TargetId))

		sourceNode := createUniqueNode(sourceId, fmt.Sprintf("%s", result.SourceName))
		targetNode := createUniqueNode(targetId, fmt.Sprintf("%s", result.TargetName))

		createRelationship(&result, sourceNode, targetNode)
	}

	fmt.Println("Migration completed")
}
