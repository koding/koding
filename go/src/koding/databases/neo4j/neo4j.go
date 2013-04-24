package neo4j

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"koding/tools/config"
	"log"
	"net/http"
	"strings"
)

var (
	BASE_URL         = config.Current.Neo4j.Host + ":" + fmt.Sprintf("%d", config.Current.Neo4j.Port)
	INDEX_NODE_PATH  = "/db/data/index/node/koding"
	UNIQUE_NODE_PATH = "/db/data/index/node/koding?unique"
	INDEX_PATH       = "/db/data/index/node"
	NODE_URL         = "/db/data/node"
)

// Gets URL and string data to be sent and makes POST request
// reads response body and returns as string
func sendRequest(requestType, url, data string) string {

	//convert string into bytestream
	dataByte := strings.NewReader(data)
	req, err := http.NewRequest(requestType, url, dataByte)

	// read response body
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Fatal(err)
	}

	body, _ := ioutil.ReadAll(res.Body)

	defer res.Body.Close()

	return string(body)

}

// connect source and target with relation property
// response will be object
func CreateRelationship(relation, source, target string) map[string]interface{} {

	relationshipData := fmt.Sprintf(`{"to" : "%s", "type" : "%s" }`, target, relation)
	relRes := sendRequest("POST", fmt.Sprintf("%s", source), relationshipData)

	relNode, err := jsonDecode(relRes)
	if err != nil {
		fmt.Println("Problem with relation response", relRes)
	}

	return relNode
}

// creates a unique node with given id and node name
// response will be Object
func CreateUniqueNode(id string, name string) map[string]interface{} {

	url := BASE_URL + UNIQUE_NODE_PATH

	postData := generatePostJsonData(id, name)

	response := sendRequest("POST", url, postData)

	node, err := jsonDecode(response)
	if err != nil {
		fmt.Println("Problem with unique node creation response", response)
	}

	return node
}

// deletes a relation between two node using relationship info
func DeleteRelationship(sourceId, targetId, relationship string) bool {

	//get source node information
	sourceInfo := GetNode(sourceId)

	//get target node information
	targetInfo := GetNode(targetId)

	// create  url to get relationship information of source node
	relationshipsURL := fmt.Sprintf("%s", sourceInfo[0]["self"]) + "/relationships/all/" + relationship

	//this request returns objects in an array
	response := sendRequest("GET", relationshipsURL, "")
	//so use json array decoder
	relationships, err := jsonArrayDecode(response)
	if err != nil {
		fmt.Println("Problem with unique node creation response", response)
	}

	//check there might be another relations
	if relationships[0]["end"] == targetInfo[0]["self"] {
		toBeDeletedRelationURL := fmt.Sprintf("%s", relationships[0]["self"])
		deletionResponse := sendRequest("DELETE", toBeDeletedRelationURL, "")
		fmt.Println(deletionResponse)
	} else {
		fmt.Println("not found!")
		fmt.Println("relationships...")
		fmt.Println(relationships)
	}
	return true
}

// gets node from neo4j with given unique node id
//response will be object
func GetNode(id string) []map[string]interface{} {

	url := BASE_URL + INDEX_NODE_PATH + "/id/" + id

	response := sendRequest("GET", url, "")

	nodeData, err := jsonArrayDecode(response)
	if err != nil {
		fmt.Println("Problem with response", response)
	}

	return nodeData
}

// creates a unique node with given id and node name

func DeleteNode(id string) bool {

	node := GetNode(id)

	nodeURL := node[0]["self"]

	url := BASE_URL + NODE_URL + fmt.Sprintf("%s", nodeURL)

	// DeleteNodeRelationships(fmt.Sprintf("%s", nodeURL))

	response := sendRequest("DELETE", url, "")

	_, err := jsonDecode(response)
	if err != nil {
		fmt.Println("Problem with response", response)
	}

	return true
}

// creates a unique tree head node to hold all nodes
// it is called once during runtime while initializing
func CreateUniqueIndex(name string) {
	//create unique index
	url := BASE_URL + INDEX_PATH

	bd := sendRequest("POST", url, `{"name":"`+name+`"}`)

	fmt.Println("Created unique index for data", bd)
}

// This is a custom json string generator as http request body to neo4j
func generatePostJsonData(id, name string) string {
	return fmt.Sprintf(`{ "key" : "id", "value" : "%s", "properties" : { "id" : "%s", "name" : "%s" } }`, id, id, name)
}

//here, mapping of decoded json
func jsonArrayDecode(data string) ([]map[string]interface{}, error) {
	var source []map[string]interface{}

	err := json.Unmarshal([]byte(data), &source)
	if err != nil {
		fmt.Println("Marshalling error:", err)
		return nil, err
	}

	return source, nil
}

//here, mapping of decoded json
func jsonDecode(data string) (map[string]interface{}, error) {
	var source map[string]interface{}

	err := json.Unmarshal([]byte(data), &source)
	if err != nil {
		fmt.Println("Marshalling error:", err)
		return nil, err
	}

	return source, nil
}
