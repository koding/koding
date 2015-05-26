package models

import "labix.org/v2/mgo/bson"

type GatherStat struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	Env        string        `bson:"env" json:"env"`
	Username   string        `bson:"username" json:"username"`
	InstanceId string        `bson:"instanceId" json:"instanceId"`
	Name       string        `bson:"name" json:"name"`
	Type       string        `bson:"type" json:"type"`
	Number     float64       `bson:"number" json:"number"`
}
