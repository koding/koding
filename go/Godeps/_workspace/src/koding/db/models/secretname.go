package models

import "gopkg.in/mgo.v2/bson"

type SecretName struct {
	Id            bson.ObjectId `bson:"_id"`
	Name          string        `bson:"name"`
	SecretName    string        `bson:"secretName"`
	OldSecretName string        `bson:"oldSecretName"`
}
