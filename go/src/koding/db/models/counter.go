package models

import "gopkg.in/mgo.v2/bson"

type Counter struct {
	ID        bson.ObjectId `bson:"_id,omitempty"`
	Namespace string        `bson:"namespace,omitempty"`
	Type      string        `bson:"type,omitempty"`
	Current   int           `bson:"current,omitempty"`
}

type Counters []*Counter

func (c Counters) Len() int           { return len(c) }
func (c Counters) Less(i, j int) bool { return c[i].ID.Hex() < c[j].ID.Hex() }
func (c Counters) Swap(i, j int)      { c[i], c[j] = c[j], c[i] }
