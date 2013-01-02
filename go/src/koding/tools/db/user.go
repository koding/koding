package db

import (
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type User struct {
	Id        int           "_id"
	Name      string        "name"
	DefaultVM bson.ObjectId "defaultVM"
}

var Users *mgo.Collection = Collection("jUsers2")

func FindUser(query interface{}) (*User, error) {
	var user User
	err := Users.Find(query).One(&user)
	return &user, err
}

func FindUserById(id int) (*User, error) {
	return FindUser(bson.M{"_id": id})
}

func FindUserByName(name string) (*User, error) {
	return FindUser(bson.M{"name": name})
}
