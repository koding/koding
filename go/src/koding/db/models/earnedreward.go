package models

import (
  "labix.org/v2/mgo/bson"
)

type EarnedReward struct {
  Id       bson.ObjectId `bson:"_id" json:"_id"`
  OriginId bson.ObjectId `bson:"originId" json:"originId"`
  Type     string        `bson:"type" json:"type"`
  Unit     string        `bson:"unit" json:"unit"`
  Amount   int           `bson:"amount" json:"amount"`
}
