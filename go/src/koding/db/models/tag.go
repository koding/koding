package models

import "labix.org/v2/mgo/bson"

type Tag struct {
  ObjectId bson.ObjectId `bson:"_id" json:"-"`
  Title    string        `bson:"title"`
  Slug     string        `bson:"slug"`
}
