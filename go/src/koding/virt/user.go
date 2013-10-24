package virt

import (
	"crypto/sha1"
	"encoding/hex"
	"koding/db/models"
)

type User models.User

const UserIdOffset = 1000000
const RootIdOffset = 500000

var RootUser = User{Uid: RootIdOffset, Name: "root"}

func (user *User) HasPassword(password string) bool {
	hash := sha1.New()
	hash.Write([]byte(user.Salt))
	hash.Write([]byte(password))
	return user.Password == hex.EncodeToString(hash.Sum(nil))
}

func (user *User) SshKeyList() []string {
	keys := make([]string, len(user.SshKeys))
	for i, entry := range user.SshKeys {
		keys[i] = entry.Key
	}
	return keys
}
