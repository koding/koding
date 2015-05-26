package models

import "labix.org/v2/mgo/bson"

type GatherError struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	Username   string        `bson:"username" json:"username"`
	InstanceId string        `bson:"instanceId" json:"instanceId"`
	Error      string        `bson:"error" json:error`
}
