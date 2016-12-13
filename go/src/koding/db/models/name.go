package models

import "gopkg.in/mgo.v2/bson"

// import "gopkg.in/mgo.v2/bson"

type Name struct {
	ID    bson.ObjectId `bson:"_id"`
	Name  string        `bson:"name"`
	Slugs []Slug        `bson:"slugs"`
}

type Slug struct {
	ConstructorName string `bson:"constructorName"`
	CollectionName  string `bson:"collectionName"`
	UsedAsPath      string `bson:"usedAsPath"`
	Slug            string `bson:"slug"`
	Group           string `bson:"group,omitempty"`
}
