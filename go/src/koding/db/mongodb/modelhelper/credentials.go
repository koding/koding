package modelhelper

import (
	"fmt"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const CredentialsColl = "jCredentials"

func GetCredentialsFromPublicKeys(publicKey ...string) ([]*models.Credential, error) {

	var credentials []*models.Credential
	if err := Mongo.Run(CredentialsColl, func(c *mgo.Collection) error {
		return c.Find(bson.M{"publicKey": bson.M{"$in": publicKey}}).All(&credentials)
	}); err != nil {
		return nil, fmt.Errorf("credentials lookup error: %v", err)
	}

	return credentials, nil
}
