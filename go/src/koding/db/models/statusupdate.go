package models

import "labix.org/v2/mgo/bson"

type StatusUpdate struct {
  Id         bson.ObjectId `bson:"_id" json:"-"`
  Slug       string        `bson:"slug"`
  Body       string        `bson:"body"`
  OriginId   bson.ObjectId `bson:"originId"`
  OriginType string        `bson:"originType"`
}
