package main

import (
	"fmt"
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type User struct {
	Id bson.ObjectId `bson:"_id"`
}

var (
	MONGO_CONNECTION              *mgo.Session
	MONGO_CONN_STRING             = config.Current.Mongo
	MONGO_DEFAULT_COLLECTION_NAME = "jUsers"
)

func GetConnection() *mgo.Session {
	if MONGO_CONNECTION == nil {
		// connnect to mongo
		var err error
		fmt.Println(MONGO_CONN_STRING)
		MONGO_CONNECTION, err = mgo.Dial(MONGO_CONN_STRING)
		if err != nil {
			fmt.Println(err)
		}
	}
	return MONGO_CONNECTION
}

func GetCollection(collectionName string) *mgo.Collection {
	session := GetConnection()
	if collectionName == "" {
		collectionName = MONGO_DEFAULT_COLLECTION_NAME
	}
	c := session.DB("").C(collectionName)
	return c
}

func main() {

	accountColl := GetCollection("")

	var result *User
	iter := accountColl.Find(nil).Iter()
	i := 1
	//iterate over results
	for iter.Next(&result) {
		fmt.Println(i)
		accountColl.UpdateId(result.Id, bson.M{"$set": bson.M{"emailFrequency.groupInvite": true}})
		accountColl.UpdateId(result.Id, bson.M{"$set": bson.M{"emailFrequency.groupRequest": true}})
		accountColl.UpdateId(result.Id, bson.M{"$set": bson.M{"emailFrequency.groupApproved": true}})
		i++
	}
	if iter.Err() != nil {
		panic(iter.Err())
	}

	fmt.Println("Migration completed")

}
