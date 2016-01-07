package modeltesthelper

import (
	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func UpdateAccountSocialApiId(accountId bson.ObjectId, socialApiId string) error {
	selector := bson.M{"_id": accountId}
	query := bson.M{"$set": bson.M{"socialApiId": socialApiId}}

	updateQuery := func(c *mgo.Collection) error {
		_, err := c.UpdateAll(selector, query)
		return err
	}

	return modelhelper.Mongo.Run(modelhelper.AccountsColl, updateQuery)
}
