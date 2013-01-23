package db

import (
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const DEFAULT_VM = "defaultVM"

type User struct {
	Id        int           `bson:"_id"`
	Name      string        `bson:"name"`
	Password  string        `bson:"password"`
	DefaultVM bson.ObjectId `bson:"defaultVM"`
}

var Users *mgo.Collection

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
