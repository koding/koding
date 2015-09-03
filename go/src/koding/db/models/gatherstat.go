package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

const (
	GatherStatAbuse     = "abuse"
	GatherStatAnalytics = "analytics"
)

type GatherStat struct {
	Id         bson.ObjectId      `bson:"_id" json:"-"`
	Env        string             `bson:"env" json:"env"`
	Username   string             `bson:"username" json:"username"`
	InstanceId string             `bson:"instanceId" json:"instanceId,omitempty"`
	Type       string             `bson:"type" json:"type"`
	CreatedAt  time.Time          `bson:"createdAt" json:"createdAt"`
	Stats      []GatherSingleStat `bson:"stats" json:"stats"`
}

type GatherError struct {
	Id         bson.ObjectId `bson:"_id" json:"-"`
	Env        string        `bson:"env" json:"env"`
	Username   string        `bson:"username" json:"username"`
	InstanceId string        `bson:"instanceId" json:"instanceId"`
	Error      string        `bson:"error" json:error`
	CreatedAt  time.Time     `bson:"createdAt" json:"createdAt"`
}

type GatherSingleStat struct {
	Name  string      `bson:"name" json:"name"`
	Type  string      `bson:"type" json:"type"`
	Value interface{} `bson:"value" json:"value"`
}

func NewGatherError() *GatherError {
	return &GatherError{
		Id:        bson.NewObjectId(),
		CreatedAt: time.Now().UTC(),
	}
}

func NewGatherStat() *GatherStat {
	return &GatherStat{
		Id:        bson.NewObjectId(),
		CreatedAt: time.Now().UTC(),
	}
}
