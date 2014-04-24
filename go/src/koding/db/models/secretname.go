package models

import "labix.org/v2/mgo/bson"

type SecretName struct {
	Id            bson.ObjectId `bson:"_id"`
	Name          string        `bson:"name"`
	SecretName    string        `bson:"secretName"`
	OldSecretName string        `bson:"oldSecretName"`
}
