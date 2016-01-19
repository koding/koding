package modelhelper

import (
	"fmt"

	"koding/db/models"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const (
	CredentialsColl     = "jCredentials"
	CredentialDatasColl = "jCredentialDatas"
)

func GetCredentialsFromIdentifiers(identifier ...string) ([]*models.Credential, error) {
	var credentials []*models.Credential
	if err := Mongo.Run(CredentialsColl, func(c *mgo.Collection) error {
		return c.Find(bson.M{"identifier": bson.M{"$in": identifier}}).All(&credentials)
	}); err != nil {
		return nil, fmt.Errorf("credentials lookup error: %v", err)
	}

	return credentials, nil
}

func GetCredentialDatasFromIdentifiers(identifier ...string) ([]*models.CredentialData, error) {
	var credentialData []*models.CredentialData

	if err := Mongo.Run(CredentialDatasColl, func(c *mgo.Collection) error {
		return c.Find(bson.M{"identifier": bson.M{"$in": identifier}}).All(&credentialData)
	}); err != nil {
		return nil, fmt.Errorf("credential data lookup error: %v", err)
	}

	return credentialData, nil
}

func UpdateCredentialData(identifier string, data bson.M) error {
	return Mongo.Run(CredentialDatasColl, func(c *mgo.Collection) error {
		return c.Update(bson.M{"identifier": identifier}, data)
	})
}

func UpdateCredential(identifier string, data bson.M) error {
	return Mongo.Run(CredentialsColl, func(c *mgo.Collection) error {
		return c.Update(bson.M{"identifier": identifier}, data)
	})
}

func SetCredentialVerified(identifier string, verified bool) error {
	return UpdateCredential(identifier, bson.M{
		"$set": bson.M{"verified": verified},
	})
}
