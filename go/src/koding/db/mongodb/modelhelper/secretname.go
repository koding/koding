package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func FetchSecretNameByName(name string) (*models.SecretName, error) {
	secretName := &models.SecretName{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"name": name}).One(secretName)
	}

	err := Mongo.Run("jSecretNames", query)
	if err != nil {
		return secretName, err
	}

	return secretName, nil
}
