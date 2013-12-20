package modelhelper

import (
  "labix.org/v2/mgo/bson"
)

type Selector bson.M

func GetObjectId(id string) bson.ObjectId {
  return bson.ObjectIdHex(id)
}

func NewObjectId() bson.ObjectId {
  return bson.NewObjectId()
}
