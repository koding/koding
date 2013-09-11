package modelhelper

import (
	"crypto/sha1"
	"fmt"
	"io"
	"koding/db/models"
	"koding/db/mongodb"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func CheckAndGetUser(username string, password string) (*models.User, error) {

	user, err := GetUser(username)
	if err != nil {
		return nil, fmt.Errorf("Username does not match")
	}

	iostring := sha1.New()
	io.WriteString(iostring, user.Salt)
	io.WriteString(iostring, password)
	sha1pass := fmt.Sprintf("%x", iostring.Sum(nil))
	if user.Password != sha1pass {
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
