package models

import "gopkg.in/mgo.v2/bson"

type AppStorage struct {
	Id      bson.ObjectId          `bson:"_id" json:"_id"`
	AppID   string                 `bson:"appId" json:"appId"`
	Version string                 `bson:"version" json:"version"`
	Bucket  map[string]interface{} `bson:"bucket" json:"bucket"`
}

type CombinedAppStorage struct {
	Id        bson.ObjectId                                `bson:"_id" json:"_id"`
	AccountId bson.ObjectId                                `bson:"accountId" json:"accountId"`
	Bucket    map[string]map[string]map[string]interface{} `bson:"bucket" json:"bucket"`
}
