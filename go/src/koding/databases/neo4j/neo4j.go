package neo4j

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"koding/tools/config"
	"log"
	"net/http"
	"strconv"
	"strings"
)

var (
	BASE_URL         = config.Current.Neo4j.Write + ":" + strconv.Itoa(config.Current.Neo4j.Port)
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

// connect source and target with relation property
// response will be object
func CreateRelationshipWithData(relation, source, target, data string) map[string]interface{} {

	relationshipData := fmt.Sprintf(`{"to" : "%s", "type" : "%s", "data" : %s }`, target, relation, data)
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

	if len(sourceInfo) < 1 || len(targetInfo) < 1 {
		return false
	}

	if _, ok := sourceInfo[0]["self"]; !ok {
		return false
	}

	if _, ok := targetInfo[0]["self"]; !ok {
		return false
	}

	// create  url to get relationship information of source node
	relationshipsURL := fmt.Sprintf("%s", sourceInfo[0]["self"]) + "/relationships/all/" + relationship

	//this request returns objects in an array
	response := sendRequest("GET", relationshipsURL, "")
	//so use json array decoder
	relationships, err := jsonArrayDecode(response)
	if err != nil {
		fmt.Println("Problem with unique node creation response", response)
		return false
	}

	if len(relationships) < 1 {
		return false
	}

	if _, ok := relationships[0]["self"]; !ok {
		return false
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

// updates node with given data
// response will be object
func UpdateNode(id, propertiesJSON string) map[string]interface{} {

	node := GetNode(id)

	//if self is not there!
	if _, ok := node[0]["self"]; !ok {
		return nil
	}

	// create  url to get relationship information of source node
	propertiesURL := fmt.Sprintf("%s", node[0]["self"]) + "/properties"

	response := sendRequest("PUT", propertiesURL, propertiesJSON)
	if response != "" {
		fmt.Println(response)
		res, err := jsonDecode(response)
		if err != nil {
			fmt.Println("Problem with response", err, res)
		}
	}

	return make(map[string]interface{})
}

func DeleteNode(id string) bool {

	node := GetNode(id)

	nodeURL := fmt.Sprintf("%s", node[0]["self"])

	relationshipsURL := nodeURL + "/relationships/all"

	response := sendRequest("GET", relationshipsURL, "")

	relations, err := jsonArrayDecode(response)
	if err != nil {
		fmt.Println("Problem with response", response)
		return false
	}

	for _, relation := range relations {
		if _, ok := relation["self"]; ok {
			relationshipURL := fmt.Sprintf("%s", relation["self"])
			fmt.Println(relationshipURL)
			sendRequest("DELETE", relationshipURL, "")
		}
	}

	sendRequest("DELETE", nodeURL, "")

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
