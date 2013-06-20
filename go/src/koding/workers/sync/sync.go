package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/siesta/neo4j"
	"io/ioutil"
	"koding/databases/mongo"
	"koding/tools/config"
	"labix.org/v2/mgo/bson"
	"log"
	"net/http"
	"strconv"
	"strings"
)

var GRAPH_URL = config.Current.Neo4j.Write + ":" + strconv.Itoa(config.Current.Neo4j.Port)

type Relationship struct {
	Id         bson.ObjectId `bson:"_id,omitempty"`
	TargetId   bson.ObjectId `bson:"targetId,omitempty"`
	TargetName string        `bson:"targetName"`
	SourceId   bson.ObjectId `bson:"sourceId,omitempty"`
	SourceName string        `bson:"sourceName"`
	As         string
	Data       bson.Binary
}

// get from mongo
// check if available worker, start go routine
// if no worker, wait till something returns

var numberOfAvailableWorkers = 500

func canStartWork() bool {
	numberOfAvailableWorkers = numberOfAvailableWorkers - 1
	if numberOfAvailableWorkers > 1 {
		return true
	}
}

func waitTillFree(doneWorking <-chan bool) {
	<-doneWorking
	numberOfAvailableWorkers = numberOfAvailableWorkers + 1
}

func main() {
	coll := mongo.GetCollection("relationships")
	query := bson.M{
		"targetName": bson.M{"$nin": notAllowedNames},
		"sourceName": bson.M{"$nin": notAllowedNames},
	}
	iter := coll.Find(query).Skip(0).Limit(1000).Sort("-timestamp").Iter()

	alertDone := make(chan bool)

	var result Relationship
	for iter.Next(&result) {
		if canStartWork() {
			work(result)
		} else {
			waitTillFree(alertDone)
		}
	}
}

func work(result Relationship, alertDone chan<- bool) {
	sourceId, err := checkNodeExists(result.SourceId.Hex())
	if err != nil {
		log.Println("SourceNode", result.SourceName, result.SourceId, err)
		alertDone <- true
		return
	}

	targetId, err := checkNodeExists(result.TargetId.Hex())
	if err != nil {
		log.Println("TargetNode", result.TargetName, result.TargetId, err)
		alertDone <- true
		return
	}

	exists, err := checkRelationshipExists(sourceId, targetId, result.As)
	if err != nil {
		log.Println("Relationship ERROR", err)
		alertDone <- true
		return
	}

	if exists == true {
		log.Println("Relationship:", result.Id.Hex(), "exists")
	} else {
		log.Println("Relationship:", result, "does not exist")
	}

	alertDone <- true
}

func getAndParse(url string) ([]byte, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	return body, nil
}

func checkRelationshipExists(sourceId, targetId, relType string) (bool, error) {
	url := fmt.Sprintf("%v/db/data/node/%v/relationships/all/%v", GRAPH_URL, sourceId, relType)

	body, err := getAndParse(url)
	if err != nil {
		return false, err
	}

	relResponse := make([]neo4j.RelationshipResponse, 1)
	err = json.Unmarshal(body, &relResponse)
	if err != nil {
		return false, err
	}

	for _, rl := range relResponse {
		id := strings.SplitAfter(rl.End, GRAPH_URL+"/db/data/node/")[1]
		if targetId == id {
			return true, nil
		}
	}

	return false, nil
}

func checkNodeExists(id string) (string, error) {
	url := fmt.Sprintf("%v/db/data/index/node/koding/id/%v", GRAPH_URL, id)
	body, err := getAndParse(url)
	if err != nil {
		return "", err
	}

	nodeResponse := make([]neo4j.NodeResponse, 1)
	err = json.Unmarshal(body, &nodeResponse)
	if err != nil {
		return "", err
	}

	if len(nodeResponse) < 1 {
		return "", errors.New("no node exists")
	}

	node := nodeResponse[0]
	idd := strings.SplitAfter(node.Self, GRAPH_URL+"/db/data/node/")

	return string(idd[1]), nil
}

var notAllowedNames = []string{
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
	"JLimit",
	"JVM",
	"JInvitationRequest",
}
