package models

import "gopkg.in/mgo.v2/bson"

// StackTemplate is a document from jStackTemplates collection
type StackTemplate struct {
	Id       bson.ObjectId `bson:"_id" json:"-"`
	Template struct {
		Content string `bson:"content"`
		Sum     string `bson:"sum"`
	} `bson:"template"`
	Credentials map[string][]string `bson:"credentials"`
}
