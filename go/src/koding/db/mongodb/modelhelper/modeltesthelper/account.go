package modeltesthelper

import (
	"koding/db/mongodb/modelhelper"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
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
