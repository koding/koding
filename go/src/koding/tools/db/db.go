package db

import (
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Counter struct {
	Value int `bson:"v"`
}

var database *mgo.Database

var counters *mgo.Collection
var Users *mgo.Collection
var VMs *mgo.Collection

func init() {
	session, err := mgo.Dial(config.Current.Mongo)
	if err != nil {
		panic(err)
	}
	session.SetSafe(&mgo.Safe{})
	database = session.DB("")
	counters = database.C("jCounters")
	Users = database.C("jUsers")
	VMs = database.C("jVMs")
}

// may panic
func NextCounterValue(counterName string) int {
	var c Counter
	if _, err := counters.FindId(counterName).Apply(mgo.Change{Update: bson.M{"$inc": bson.M{"v": 1}}}, &c); err != nil {
		panic(err)
	}
	return c.Value
}
