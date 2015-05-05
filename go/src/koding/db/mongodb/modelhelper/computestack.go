package modelhelper

import (
	"fmt"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const ComputeStackColl = "jComputeStack"

func GetComputeStack(id string) (*models.ComputeStack, error) {
	if !bson.IsObjectIdHex(id) {
		return nil, fmt.Errorf("Not valid ObjectIdHex: '%s'", id)
	}

	computeStack := new(models.ComputeStack)
	query := func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(&computeStack)
	}

	if err := Mongo.Run(ComputeStackColl, query); err != nil {
		return nil, err
	}

	return computeStack, nil
}
