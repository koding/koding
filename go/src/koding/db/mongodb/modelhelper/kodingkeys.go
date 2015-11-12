package modelhelper

import (
	"fmt"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

// NewKodingKeys returns a new instance of *models.KodingKeys
func NewKodingKeys() *models.KodingKeys {
	return &models.KodingKeys{
		Id: bson.NewObjectId(),
	}
}

// GetKodingKeys returns a *models.KodingKeys that matches both username
// and key fields from the jKodingKeys collection.
func GetKodingKeysByUsername(username, hostname string) (*models.KodingKeys, error) {
	kodingKeys := new(models.KodingKeys)
	user, err := GetUser(username)
	if err != nil {
		return nil, fmt.Errorf("could not fetch user '%s', err: '%s'", username, err)
	}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{
			"hostname": hostname,
			"owner":    user.ObjectId.Hex(),
		}).One(kodingKeys)
	}

	err = Mongo.Run("jKodingKeys", query)
	if err != nil {
		return nil, err
	}

	return kodingKeys, nil
}

func GetKodingKeysByKey(key string) (*models.KodingKeys, error) {
	kodingKeys := new(models.KodingKeys)
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"key": key}).One(kodingKeys)
	}

	err := Mongo.Run("jKodingKeys", query)
	if err != nil {
		return nil, err
	}

	return kodingKeys, nil
}

// AddKodingKeys upserts a model.KodingKeys document into the jKodingKeys collection.
// Upsert matchin is based on model.KodingKeys.Key.
func AddKodingKeys(k *models.KodingKeys) error {
	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"hostname": k.Hostname}, k)
		if err != nil {
			fmt.Println("AddKodingKeys error", err)
			return fmt.Errorf("could not add key '%s', err :'%s'", k.Key, err)
		}
		return nil
	}

	return Mongo.Run("jKodingKeys", query)
}
