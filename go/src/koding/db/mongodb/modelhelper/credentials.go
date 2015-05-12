package modelhelper

import (
	"fmt"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const (
	CredentialsColl     = "jCredentials"
	CredentialDatasColl = "jCredentialDatas"
)

func GetCredentialsFromPublicKeys(publicKey ...string) ([]*models.Credential, error) {
	var credentials []*models.Credential
	if err := Mongo.Run(CredentialsColl, func(c *mgo.Collection) error {
		return c.Find(bson.M{"publicKey": bson.M{"$in": publicKey}}).All(&credentials)
	}); err != nil {
		return nil, fmt.Errorf("credentials lookup error: %v", err)
	}

	return credentials, nil
}

func GetCredentialDatasFromPublicKeys(publicKey ...string) ([]*models.CredentialData, error) {
	var credentialData []*models.CredentialData

	if err := Mongo.Run(CredentialDatasColl, func(c *mgo.Collection) error {
		return c.Find(bson.M{"publicKey": bson.M{"$in": publicKey}}).All(&credentialData)
	}); err != nil {
		return nil, fmt.Errorf("credential data lookup error: %v", err)
	}

	return credentialData, nil
}

func UpdateCredentialData(publicKey string, data bson.M) error {
	return Mongo.Run(CredentialDatasColl, func(c *mgo.Collection) error {
		return c.Update(bson.M{"publicKey": publicKey}, data)
	})
}

func UpdateCredential(publicKey string, data bson.M) error {
	return Mongo.Run(CredentialsColl, func(c *mgo.Collection) error {
		return c.Update(bson.M{"publicKey": publicKey}, data)
	})
}
