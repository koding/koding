package models

import "gopkg.in/mgo.v2/bson"

type GatherStat struct {
	Id         bson.ObjectId      `bson:"_id" json:"-"`
	Env        string             `bson:"env" json:"env"`
	Username   string             `bson:"username" json:"username"`
	InstanceId string             `bson:"instanceId" json:"instanceId"`
	Stats      []GatherSingleStat `bson:"stats" json:"stats"`
}

type GatherError struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	Env        string        `bson:"env" json:"env"`
	Username   string        `bson:"username" json:"username"`
	InstanceId string        `bson:"instanceId" json:"instanceId"`
	Error      string        `bson:"error" json:error`
}

type GatherSingleStat struct {
	Name  string      `bson:"name" json:"name"`
	Type  string      `bson:"type" json:"type"`
	Value interface{} `bson:"value" json:"value"`
}

func NewGatherError(err error) *GatherError {
	return &GatherError{Error: err.Error()}
}

func NewGatherStat(results []GatherSingleStat) *GatherStat {
	return &GatherStat{Stats: results}
}
