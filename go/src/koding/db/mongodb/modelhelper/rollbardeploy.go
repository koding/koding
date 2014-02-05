package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var RollbarDeployCollection = "roll"

func SaveUniqueByDeployId(r *models.RollbarDeploy) error {
	var count int
	var err error
	var findQuery = func(c *mgo.Collection) error {
		count, err = c.Find(bson.M{"deployId": r.DeployId}).Count()

		return err
	}

	err = Mongo.Run(r.CollectionName(), findQuery)
	if err != nil {
		return err
	}

	if count > 0 {
		return nil
	}

	var insertQuery = func(c *mgo.Collection) error {
		return c.Insert(r)
	}

	return Mongo.Run(r.CollectionName(), insertQuery)
}

func UpdateAlertStatus(r *models.RollbarDeploy) error {
	var query = func(c *mgo.Collection) error {
		var findQuery = bson.M{"_id": r.Id}
		var updateQuery = bson.M{"$set": bson.M{"alerted": true}}

		return c.Update(findQuery, updateQuery)
	}

	return Mongo.Run(r.CollectionName(), query)
}

func GetLatestDeploy() (*models.RollbarDeploy, error) {
	r := new(models.RollbarDeploy)

	var findQuery = func(c *mgo.Collection) error {
		return c.Find(nil).Sort("-deployId").One(&r)
	}

	if err := Mongo.Run(r.CollectionName(), findQuery); err != nil {
		return r, err
	}

	return r, nil
}
