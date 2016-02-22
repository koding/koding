package modelhelper

import (
	"koding/db/models"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const (
	CombinedAppStorageColl = "jCombinedAppStorages"
	AppStorageColl         = "jAppStorages"
)

func GetCombinedAppStorageByAccountId(accountId bson.ObjectId) (*models.CombinedAppStorage, error) {
	appStorage := &models.CombinedAppStorage{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"accountId": accountId}).One(appStorage)
	}

	return appStorage, Mongo.Run(CombinedAppStorageColl, query)
}

// GetAppStoragesByIds fetches all the AppStorages given by their IDs
func GetAppStoragesByIds(ids ...bson.ObjectId) ([]*models.AppStorage, error) {
	appStorages := make([]*models.AppStorage, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": ids}}).All(&appStorages)
	}

	return appStorages, Mongo.Run(AppStorageColl, query)
}

func CreateCombinedAppStorage(a *models.CombinedAppStorage) error {
	query := insertQuery(a)
	return Mongo.Run(CombinedAppStorageColl, query)
}

func UpdateCombinedAppStorage(a *models.CombinedAppStorage) error {
	query := func(c *mgo.Collection) error {
		return c.UpdateId(a.Id, a)
	}

	return Mongo.Run(CombinedAppStorageColl, query)
}
