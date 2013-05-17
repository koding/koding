package main

import (
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
	"runtime"
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

var mongo_url = config.Current.Mongo

func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())

	session, err := mgo.Dial(mongo_url)
	if err != nil {
		log.Fatal(err)
	}

	defer session.Close()

	var relationship *Relationship
	rels := session.DB("").C("relationships")

	done := make(chan bool)
	allDone := make(chan bool)

	total := 1000000
	iter := rels.Find(nil).Batch(1000).Limit(total).Iter()
	log.Println("found results")
	count := 0

	go func() {
		for {
			<-done
			count++
			/*log.Println(count)*/
			if count >= total {
				allDone <- true
				break
			}
		}
	}()

	for iter.Next(&relationship) {
		go func() {
			time.Sleep(100 * time.Millisecond)
			done <- true
		}()
	}

	<-allDone
	log.Println(count)
}
