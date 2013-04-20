package main

import (
	"fmt"
	// "koding/tools/config"
	"koding/databases/neo4j"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
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
	MONGO_CONN_STRING = "mongodb://dev:k9lc4G1k32nyD72@web-dev.in.koding.com:27017/koding_dev2_copy"
)

func main() {
	// connnect to mongo
	conn, err := mgo.Dial(MONGO_CONN_STRING)
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	conn.SetMode(mgo.Monotonic, true)

	neo4j.CreateUniqueIndex("koding")

	relationshipColl := conn.DB("koding_dev2_copy").C("relationships")

	var result Relationship
	iter := relationshipColl.Find(nil).Iter()

	//iterate over results
	for iter.Next(&result) {
		sourceNode := neo4j.CreateUniqueNode(result.SourceId.Hex(), result.SourceName)
		targetNode := neo4j.CreateUniqueNode(result.TargetId.Hex(), result.TargetName)

		source := fmt.Sprintf("%s", sourceNode["create_relationship"])
		target := fmt.Sprintf("%s", targetNode["self"])
		neo4j.CreateRelationship(result.As, source, target)
	}

	fmt.Println("Migration completed")
}
