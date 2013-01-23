package db

import (
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Counter struct {
	Value int `bson:"v"`
}

var database *mgo.Database
var counters *mgo.Collection

func init() {
	session, err := mgo.Dial("dev:GnDqQWt7iUQK4M@miles.mongohq.com:10057/koding_dev2")
	if err != nil {
		panic(err)
	}
	session.SetSafe(&mgo.Safe{})
	database = session.DB("koding_dev2")
	counters = database.C("jCounters")
	Users = database.C("jUsers2")
}

func Collection(name string) *mgo.Collection {
	return database.C(name)
}

// may panic
func NextCounterValue(counterName string) int {
	var c Counter
	if _, err := counters.FindId(counterName).Apply(mgo.Change{Update: bson.M{"$inc": bson.M{"v": 1}}}, &c); err != nil {
		panic(err)
	}
	return c.Value
}
