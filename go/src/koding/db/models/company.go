package models

import "gopkg.in/mgo.v2/bson"

type Company struct {
	Id        bson.ObjectId `bson:"_id" json:"-"`
	Name      string        `bson:"name" json:"-"`
	Slug      string        `bson:"slug" json:"-"`
	Employees int           `bson:"employees" json:"-"`
	Domain    int           `bson:"domain" json:"-"`
}
