package models

import (
	"labix.org/v2/mgo/bson"
	"net/rpc"
	"time"
)

type Kite struct {
	KiteBase  `bson:",inline"`
	UpdatedAt time.Time   `bson:"updatedAt"`
	Client    *rpc.Client `bson:"-" json:"-"`
}

type KiteBase struct {
	Id        bson.ObjectId `bson:"_id" json:"-"`
	Username  string        `bson:"username" json:"username"`
	Kitename  string        `bson:"kitename" json:"kitename"`
	Version   string        `bson:"version" json:"version"`
	PublicKey string        `bson:"publicKey" json:"publicKey"`
	Token     string        `bson:"token" json:"token"`
	Uuid      string        `bson:"uuid" json:"uuid"`
	Hostname  string        `bson:"hostname" json:"hostname"`
	Addr      string        `bson:"addr" json:"addr"`

	// this is used temporary to distinguish kites that are used for Koding
	// client-side. An example is to use it with value "vm"
	Kind string `bson:"kind" json:"kind"`

	LocalIP  string `bson:"localIP" json:"localIP"`
	PublicIP string `bson:"publicIP" json:"publicIP"`
	Port     string `bson:"port" json:"port"`
}
