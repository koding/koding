package neo4j

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"koding/tools/config"
	"koding/tools/logger"
	"koding/tools/statsd"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"labix.org/v2/mgo/bson"
)

var (
	BASE_URL         string
	CYPHER_URL       string
	INDEX_NODE_PATH  = "/db/data/index/node/koding"
	UNIQUE_NODE_PATH = "/db/data/index/node/koding?unique"
	INDEX_PATH       = "/db/data/index/node"
	NODE_URL         = "/db/data/node"
	MAX_RETRIES      = 5
	TIMEOUT          = 20
	DEADLINE         = 40
	CYPHER_PATH      = "db/data/cypher"
)

func init() {
	statsd.SetAppName("neo4j")
}

var log = logger.New("neo4jfeeder")

type Relationship struct {
	Id         bson.ObjectId `bson:"_id,omitempty"`
	TargetId   bson.ObjectId `bson:"targetId,omitempty"`
	TargetName string        `bson:"targetName"`
	SourceId   bson.ObjectId `bson:"sourceId,omitempty"`
	SourceName string        `bson:"sourceName"`
	As         string        `bson:"as"`
	Timestamp  time.Time     `bson:"timestamp"`
	Data       bson.Binary
}

func SetupNeo4j(c *config.Config) {
	BASE_URL = c.Neo4j.Write + ":" + strconv.Itoa(c.Neo4j.Port)
	CYPHER_URL = fmt.Sprintf("%v/%v", BASE_URL, CYPHER_PATH)
}

func GetBaseURL() string {
	if BASE_URL == "" {
		log.Fatal("Base url is not set. Please call SetupNeo4j() before you use this pkg.")
	}

	return BASE_URL
}

// Setup the dial timeout
func dialTimeout(timeout time.Duration, deadline time.Duration) func(network, addr string) (c net.Conn, err error) {
	return func(netw, addr string) (net.Conn, error) {
		conn, err := net.DialTimeout(netw, addr, timeout)
		if err != nil {
			return nil, err
		}
		conn.SetDeadline(time.Now().Add(deadline))
		return conn, nil
	}
}

// Gets URL and string data to be sent and makes POST request
// reads response body and returns as string
func sendRequest(requestType, url, data string, attempt int) string {
	sTimer := statsd.StartTimer("sendRequest")

	// Set the timeout & deadline
	timeOut := time.Duration(TIMEOUT) * time.Second
	deadLine := time.Duration(DEADLINE) * time.Second

	transport := http.Transport{
		Dial: dialTimeout(timeOut, deadLine),
	}

	client := http.Client{
		Transport: &transport,
	}

	//convert string into bytestream
	dataByte := strings.NewReader(data)
	req, err := http.NewRequest(requestType, url, dataByte)

	// read response body
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")
	res, err := client.Do(req)
	if err != nil && attempt <= MAX_RETRIES {
		sTimer.Failed()
		log.Error("Request timed out: %v", err)
		attempt++
		sendRequest(requestType, url, data, attempt)
	}
	if err != nil && attempt > MAX_RETRIES {
		log.Error("req to %v timed out after %v retries", url, attempt)
	}

	body, _ := ioutil.ReadAll(res.Body)

	defer res.Body.Close()

	sTimer.Success()

	return string(body)
}

// connect source and target with relation property
// response will be object
func CreateRelationship(relation, source, target string) map[string]interface{} {
	sTimer := statsd.StartTimer("CreateRelationship")

	relationshipData := fmt.Sprintf(`{"to" : "%s", "type" : "%s" }`, target, relation)
	relRes := sendRequest("POST", fmt.Sprintf("%s", source), relationshipData, 1)

	relNode, err := jsonDecode(relRes)
	if err != nil {
		log.Error("Problem with relation response %v", relRes)
		sTimer.Failed()

		return relNode
	}

	sTimer.Success()

	return relNode
}

// connect source and target with relation property
// response will be object
func CreateRelationshipWithData(relation, source, target, data string) map[string]interface{} {
	sTimer := statsd.StartTimer("CreateRelationshipWithData")

	relationshipData := fmt.Sprintf(`{"to" : "%s", "type" : "%s", "data" : %s }`, target, relation, data)
	relRes := sendRequest("POST", fmt.Sprintf("%s", source), relationshipData, 1)

	relNode, err := jsonDecode(relRes)
	if err != nil {
		sTimer.Failed()
		log.Error("Problem with relation response %v", relRes)

		return relNode
	}

	sTimer.Success()

	return relNode
}

// creates a unique node with given id and node name
// response will be Object
func CreateUniqueNode(id string, name string) map[string]interface{} {
	sTimer := statsd.StartTimer("CreateUniqueNode")

	url := GetBaseURL() + UNIQUE_NODE_PATH

	postData := generatePostJsonData(id, name)

	response := sendRequest("POST", url, postData, 1)

	node, err := jsonDecode(response)
	if err != nil {
		log.Error("Problem with unique node creation response %v", response)
		sTimer.Failed()
	} else {
		sTimer.Success()
	}

	return node
}

// deletes a relation between two node using relationship info
func DeleteRelationship(sourceId, targetId, relationship string) bool {
	sTimer := statsd.StartTimer("DeleteRelationship")

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
	response := sendRequest("GET", relationshipsURL, "", 1)
	//so use json array decoder
	relationships, err := jsonArrayDecode(response)
	if err != nil {
		log.Error("Problem with unique node creation response %v", response)
		return false
	}

	if len(relationships) < 1 {
		return false
	}

	if _, ok := relationships[0]["self"]; !ok {
		return false
	}

	foundNode := false

	for _, relation := range relationships {
		if relation["end"] == targetInfo[0]["self"] {
			toBeDeletedRelationURL := fmt.Sprintf("%s", relation["self"])
			sendRequest("DELETE", toBeDeletedRelationURL, "", 1)
			foundNode = true

			break
		}
	}

	if !foundNode {
		sTimer.Failed()
		log.Error("not found! %v", relationships[0]["self"])
	} else {
		sTimer.Success()
	}

	return true
}

// gets node from neo4j with given unique node id
//response will be object
func GetNode(id string) []map[string]interface{} {

	url := GetBaseURL() + INDEX_NODE_PATH + "/id/" + id

	response := sendRequest("GET", url, "", 1)

	nodeData, err := jsonArrayDecode(response)
	if err != nil {
		log.Error("Problem with response %v", response)
	}

	return nodeData
}

// updates node with given data
// response will be object
func UpdateNode(id, propertiesJSON string) map[string]interface{} {

	node := GetNode(id)

	if len(node) < 1 {
		return nil
	}

	//if self is not there!
	if _, ok := node[0]["self"]; !ok {
		return nil
	}

	// create  url to get relationship information of source node
	propertiesURL := fmt.Sprintf("%s", node[0]["self"]) + "/properties"

	response := sendRequest("PUT", propertiesURL, propertiesJSON, 1)
	if response != "" {
		res, err := jsonDecode(response)
		if err != nil {
			log.Error("Problem with response %v, %v", err, res)
		}
	}

	return make(map[string]interface{})
}

func DeleteNode(id string) bool {
	sTimer := statsd.StartTimer("DeleteNode")

	node := GetNode(id)

	if len(node) < 1 {
		sTimer.Failed()
		return false
	}

	//if self is not there!
	selfUrl, ok := node[0]["self"]
	if !ok {
		sTimer.Failed()
		return false
	}

	splitStrings := strings.Split(selfUrl.(string), "/")
	nodeId := splitStrings[len(splitStrings)-1]

	query := fmt.Sprintf(`
    {"query" : "START n=node(%v) MATCH n-[r?]-items DELETE r, n"}
  `, nodeId)

	response := sendRequest("POST", CYPHER_URL, query, 1)

	var result map[string][]interface{}
	err := json.Unmarshal([]byte(response), &result)
	if err != nil {
		sTimer.Failed()
		log.Error("Deleting node Marshalling error: %v", err)
		return false
	}

	sTimer.Success()

	return true
}

// creates a unique tree head node to hold all nodes
// it is called once during runtime while initializing
func CreateUniqueIndex(name string) {
	//create unique index
	url := GetBaseURL() + INDEX_PATH

	bd := sendRequest("POST", url, `{"name":"`+name+`"}`, 1)

	log.Info("Created unique index for data: %v", bd)
}

// This is a custom json string generator as http request body to neo4j
func generatePostJsonData(id, name string) string {
	return fmt.Sprintf(`{ "key" : "id", "value" : "%s", "properties" : { "id" : "%s", "name" : "%s" } }`, id, id, name)
}

//here, mapping of decoded json
func jsonArrayDecode(data string) ([]map[string]interface{}, error) {
	sTimer := statsd.StartTimer("jsonArrayDecode")

	var source []map[string]interface{}

	err := json.Unmarshal([]byte(data), &source)
	if err != nil {
		sTimer.Failed()
		log.Error("Marshalling error: %v", err)
		return nil, err
	}

	sTimer.Success()

	return source, nil
}

//here, mapping of decoded json
func jsonDecode(data string) (map[string]interface{}, error) {
	var source map[string]interface{}

	err := json.Unmarshal([]byte(data), &source)
	if err != nil {
		log.Error("Marshalling error: %v", err)
		return nil, err
	}

	return source, nil
}

var NotAllowedNames = []string{
	"CStatusActivity",
	"CStatus",

	"CFolloweeBucketActivity",
	"CFolloweeBucket",

	"CFollowerBucketActivity",
	"CFollowerBucket",

	"GroupJoineeBucketActivity",
	"GroupJoineeBucket",

	"GroupJoinerBucketActivity",
	"GroupJoinerBucket",

	"CInstalleeBucketActivity",
	"CInstalleeBucket",

	"CInstallerBucketActivity",
	"CInstallerBucket",

	"CLikeeBucketActivity",
	"CLikeeBucket",

	"CLikerBucketActivity",
	"CLikerBucket",

	"CReplieeBucketActivity",
	"CReplieeBucket",

	"CReplierBucketActivity",
	"CReplierBucket",

	"CCodeSnipActivity",
	"CCodeSnip",

	"CDiscussionActivity",
	"CDiscussion",

	"CBlogPostActivity",
	"CBlogPost",

	"CNewMemberBucketActivity",
	"CNewMemberBucket",

	"CRunnableActivity",
	"CRunnable",

	"CTutorialActivity",
	"CTutorial",

	"CActivity",
	"JAppStorage",
	"JFeed",

	"JBlogPost",
	"JChatConversation",
	"JCodeShare",
	"JCodeSnip",
	"JConversationSlice",
	"JDiscussion",
	"JDomainStat",
	"JDomain",
	"JEmailConfirmation",
	"JEmailNotification",
	"JEnvironment",
	"JGroupBundle",
	"JGuest",
	"JInvitationRequest",
	"JInvitation",
	"JKodingKey",
	"JLimit",
	"JLocationStates",
	"JLocation",
	"JMailNotification",
	"JMails",
	"JMarkdownDoc",
	"JMembershipPolicy",
	"JMessage",
	"JName",
	"JOpinion",
	"JPasswordRecovery",
	"JPrivateMessage",
	"JReferrableEmail",
	"JReferral",
	"JStatusUpdate",
	"JStorage",
	"JVM",
	"JApp",
}
