package main

import (
	"fmt"
	"koding/databases/mongo"
	"koding/databases/neo4j"
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
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
	Timestamp  time.Time `bson:"timestamp"`
}

var (
	SAVED_DATA            = make(map[string]interface{})
	MONGO_CONNECTION      *mgo.Session
	MONGO_CONN_STRING     = config.Current.Mongo
	MONGO_COLLECTION_NAME = "relationships"
)

func main() {

	if MONGO_CONNECTION == nil {
		// connnect to mongo
		var err error
		fmt.Println(MONGO_CONN_STRING)
		MONGO_CONNECTION, err = mgo.Dial(MONGO_CONN_STRING)
		if err != nil {
			fmt.Println(err)
		}
	}

	defer MONGO_CONNECTION.Close()

	neo4j.CreateUniqueIndex("koding")

	relationshipColl := MONGO_CONNECTION.DB("").C(MONGO_COLLECTION_NAME)

	// we need to iterate all over the table, fetching all documents is not a clear way!
	//this is cool
	var result *Relationship

	i := 0
	iter := relationshipColl.Find(nil).Skip(8100000).Limit(100000).Iter()

	//iterate over results
	for iter.Next(&result) {

		i += 1
		fmt.Println(i)

		if result.SourceName == "JAppStorage" || result.TargetName == "JAppStorage" || result.SourceName == "JFeed" || result.TargetName == "JFeed" || strings.HasSuffix(result.SourceName, "Bucket") || strings.HasSuffix(result.TargetName, "Bucket") || strings.HasSuffix(result.SourceName, "BucketActivity") || strings.HasSuffix(result.TargetName, "BucketActivity") {
			continue
		}

		hexSourceId := fmt.Sprintf("%s", result.SourceId.Hex())
		hexTargetId := fmt.Sprintf("%s", result.TargetId.Hex())

		// first find source
		if result.SourceName != "" {
			sourceContent := ""
			targetContent := ""
			var err error
			if _, ok := SAVED_DATA[hexSourceId]; ok {
				sourceContent = fmt.Sprintf("%s", SAVED_DATA[hexSourceId])
			} else {
				sourceContent, err = mongo.FetchContent(result.SourceId, result.SourceName)
			}
			fmt.Println("sourcefetched")
			if err != nil {
				fmt.Println("source err ", err)
				fmt.Println(hexSourceId, result.SourceName)
			} else {
				//then find target
				if result.TargetName != "" {
					if _, ok := SAVED_DATA[hexTargetId]; ok {
						targetContent = fmt.Sprintf("%s", SAVED_DATA[hexTargetId])
					} else {
						targetContent, err = mongo.FetchContent(result.TargetId, result.TargetName)
					}

					fmt.Println("targetfetched")
					if err != nil {
						fmt.Println("target err ", err)
						fmt.Println(hexTargetId, result.TargetName)
					} else {

						sourceNode := neo4j.CreateUniqueNode(hexSourceId, result.SourceName)
						fmt.Println("source unique id created")
						targetNode := neo4j.CreateUniqueNode(hexTargetId, result.TargetName)
						fmt.Println("target unique id created")
						source := fmt.Sprintf("%s", sourceNode["create_relationship"])
						target := fmt.Sprintf("%s", targetNode["self"])

						//UTC for date time uniqueness
						//format is a Go woodoo :)
						relationshipData := fmt.Sprintf(`{"createdAt" : "%s"}`, result.Timestamp.UTC().Format("2006-01-02T15:04:05Z"))
						neo4j.CreateRelationshipWithData(result.As, source, target, relationshipData)

						if _, ok := SAVED_DATA[hexSourceId]; !ok {
							neo4j.UpdateNode(hexSourceId, sourceContent)
							SAVED_DATA[hexSourceId] = sourceContent
						}

						if _, ok := SAVED_DATA[hexTargetId]; !ok {
							neo4j.UpdateNode(hexTargetId, targetContent)
							SAVED_DATA[hexTargetId] = targetContent
						}

					}
				} else {
					fmt.Println("target name not given:", hexTargetId, result.TargetName)
				}

			}
		} else {
			fmt.Println("source name not given:", hexSourceId, result.SourceName)
		}
	}

	fmt.Println("Migration completed")
}
