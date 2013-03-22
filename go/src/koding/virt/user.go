package virt

import (
	"crypto/sha1"
	"encoding/hex"
	"labix.org/v2/mgo/bson"
)

type User struct {
	ObjectId  bson.ObjectId `bson:"_id"`
	Uid       int           `bson:"uid"`
	Name      string        `bson:"username"`
	Password  string        `bson:"password"`
	Salt      string        `bson:"salt"`
	DefaultVM bson.ObjectId `bson:"defaultVM"`
}

func (user *User) HasPassword(password string) bool {
	hash := sha1.New()
	hash.Write([]byte(user.Salt))
	hash.Write([]byte(password))
	return user.Password == hex.EncodeToString(hash.Sum(nil))
}
