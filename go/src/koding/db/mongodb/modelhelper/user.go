package modelhelper

import (
	"crypto/sha1"
	"encoding/hex"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

// CheckAndGetUser validates the user with the given password. If not
// successfull it returns nil
func CheckAndGetUser(username string, password string) (*models.User, error) {
	user, err := GetUser(username)
	if err != nil {
		return nil, fmt.Errorf("Username does not match")
	}

	hash := sha1.New()
	hash.Write([]byte(user.Salt))
	hash.Write([]byte(password))

	if user.Password != hex.EncodeToString(hash.Sum(nil)) {
		return nil, fmt.Errorf("Password does not match")
	}

	return user, nil
}

func GetUser(username string) (*models.User, error) {
	user := new(models.User)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).One(&user)
	}

	err := mongodb.Run("jUsers", query)
	if err != nil {
		return nil, err
	}

	return user, nil
}
