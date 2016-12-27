package modelhelper

import (
	"koding/db/models"

	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const (
	CombinedAppStorageColl = "jCombinedAppStorages"
)

// RemoveCombinedAppStorage removes given cas
func RemoveCombinedAppStorage(id bson.ObjectId) error {
	return RemoveDocument(CombinedAppStorageColl, id)
}

func GetCombinedAppStorageByAccountId(accountId bson.ObjectId) (*models.CombinedAppStorage, error) {
	appStorage := &models.CombinedAppStorage{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"accountId": accountId}).One(appStorage)
	}

	return appStorage, Mongo.Run(CombinedAppStorageColl, query)
}
func GetAllCombinedAppStorageByAccountId(accountId bson.ObjectId) ([]models.CombinedAppStorage, error) {
	appStorages := make([]models.CombinedAppStorage, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"accountId": accountId}).All(&appStorages)
	}

	return appStorages, Mongo.Run(CombinedAppStorageColl, query)
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
