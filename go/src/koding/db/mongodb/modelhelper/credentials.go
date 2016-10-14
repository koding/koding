package modelhelper

import (
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
		return nil, err
	}

	return credentials, nil
}

func GetCredential(identifier string) (*models.Credential, error) {
	var credential models.Credential

	err := Mongo.Run(CredentialsColl, func(c *mgo.Collection) error {
		return c.Find(bson.M{"identifier": identifier}).One(&credential)
	})

	if err != nil {
		return nil, err
	}

	return &credential, nil
}

func GetCredentialByID(id bson.ObjectId) (*models.Credential, error) {
	var credential models.Credential

	return &credential, Mongo.Run(CredentialsColl, func(c *mgo.Collection) error {
		return c.FindId(id).One(&credential)
	})
}

func GetCredentialByIDs(ids ...bson.ObjectId) ([]*models.Credential, error) {
	var creds []*models.Credential

	return creds, Mongo.Run(CredentialsColl, func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": ids}}).All(&creds)
	})
}

func GetCredentialDatasFromIdentifiers(identifier ...string) ([]*models.CredentialData, error) {
	var credentialData []*models.CredentialData

	if err := Mongo.Run(CredentialDatasColl, func(c *mgo.Collection) error {
		return c.Find(bson.M{"identifier": bson.M{"$in": identifier}}).All(&credentialData)
	}); err != nil {
		return nil, err
	}

	return credentialData, nil
}

func InsertCredential(cred *models.Credential, data *models.CredentialData) error {
	err := Mongo.Run(CredentialsColl, func(c *mgo.Collection) error {
		return c.Insert(cred)
	})
	if err != nil {
		return err
	}
	return Mongo.Run(CredentialDatasColl, func(c *mgo.Collection) error {
		return c.Insert(data)
	})
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

func CreateCredential(cred *models.Credential) error {
	return Mongo.Run(CredentialsColl, func(c *mgo.Collection) error {
		return c.Insert(cred)
	})
}

func SetCredentialVerified(identifier string, verified bool) error {
	return UpdateCredential(identifier, bson.M{
		"$set": bson.M{"verified": verified},
	})
}
