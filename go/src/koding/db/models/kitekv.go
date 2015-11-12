// this collection is used for kite datastore get/set commands

package models

import (
	"time"

	"labix.org/v2/mgo/bson"
)

type KiteKeyValue struct {
	Id          bson.ObjectId `bson:"_id,omitempty" json:"-"`
	Key         string        `bson:"key"`
	Value       string        `bson:"value"`
	Username    string        `bson:"username"`
	KiteName    string        `bson:"kitename"`
	Environment string        `bson:"environment"`
	ModifiedAt  time.Time     `bson:"modifiedAt"`
}
