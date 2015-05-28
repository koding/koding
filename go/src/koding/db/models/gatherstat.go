package models

import "labix.org/v2/mgo/bson"

type Gather struct {
	Env        string `bson:"env" json:"env"`
	Username   string `bson:"username" json:"username"`
	InstanceId string `bson:"instanceId" json:"instanceId"`
}

type GatherStat struct {
	Id bson.ObjectId `bson:"_id" json:"-"`
	*Gather
	Stats []GatherSingleStat `bson:"stats" json:"stats"`
}

type GatherError struct {
	Id bson.ObjectId `bson:"_id" json:"-"`
	*Gather
	Error string `bson:"error" json:error`
}

type GatherSingleStat struct {
	Name   string  `bson:"name" json:"name"`
	Type   string  `bson:"type" json:"type"`
	Number float64 `bson:"number" json:"number"`
}

func NewGatherError(g *Gather, err error) *GatherError {
	return &GatherError{bson.NewObjectId(), g, err.Error()}
}

func NewGatherStat(g *Gather, results []GatherSingleStat) *GatherStat {
	return &GatherStat{bson.NewObjectId(), g, results}
}
