package modelhelper

import (
	"koding/db/models"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
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

func FlattenSecretName(secretName *models.SecretName, err error) ([]string, error) {
	if err != nil {
		return nil, err
	}

	secretNames := make([]string, 0)

	if secretName.SecretName != "" {
		secretNames = append(secretNames, secretName.SecretName)
	}

	if secretName.OldSecretName != "" {
		secretNames = append(secretNames, secretName.OldSecretName)
	}

	return secretNames, nil
}

func FetchFlattenedSecretName(name string) ([]string, error) {
	return FlattenSecretName(FetchSecretNameByName(name))
}
