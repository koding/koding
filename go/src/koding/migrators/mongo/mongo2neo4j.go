package main

import (
	"fmt"
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
	MONGO_CONN_STRING     = "mongodb://PROD-koding:34W4BXx595ib3J72k5Mh@web-prod.in.koding.com:27017/" + MONGO_DATABASE_NAME
	MONGO_DATABASE_NAME   = "beta_koding"
	MONGO_COLLECTION_NAME = "relationships"
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

	relationshipColl := conn.DB(MONGO_DATABASE_NAME).C(MONGO_COLLECTION_NAME)

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
