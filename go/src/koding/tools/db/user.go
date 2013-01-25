package db

import (
	"crypto/sha1"
	"encoding/hex"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const DEFAULT_VM = "defaultVM"

type User struct {
	ObjectId  bson.ObjectId `bson:"_id"`
	Uid       int           `bson:"uid"`
	Name      string        `bson:"username"`
	Password  string        `bson:"password"`
	Salt      string        `bson:"salt"`
	DefaultVM bson.ObjectId `bson:"defaultVM"`
}

var Users *mgo.Collection

func FindUser(query interface{}) (*User, error) {
	var user User
	err := Users.Find(query).One(&user)
	if err == nil && user.Uid == 0 {
		panic("User lookup returned uid 0.")
	}
	return &user, err
}

func FindUserByObjectId(id bson.ObjectId) (*User, error) {
	return FindUser(bson.M{"_id": id})
}

func FindUserByUid(id int) (*User, error) {
	return FindUser(bson.M{"uid": id})
}

func FindUserByName(name string) (*User, error) {
	return FindUser(bson.M{"username": name})
}

func (user *User) HasPassword(password string) bool {
	hash := sha1.New()
	hash.Write([]byte(user.Salt))
	hash.Write([]byte(password))
	return user.Password == hex.EncodeToString(hash.Sum(nil))
}
