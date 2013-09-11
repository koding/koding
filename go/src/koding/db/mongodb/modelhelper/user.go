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

func CheckAndGetUser(username string, password string) (models.User, error) {
	user := models.User{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).One(&user)
	}
	err := mongodb.Run("jUsers", query)
	if err != nil {
		return user, err
	}

	iostring := sha1.New()
	io.WriteString(iostring, user.Salt)
	io.WriteString(iostring, password)
	sha1pass := fmt.Sprintf("%x", iostring.Sum(nil))
	if user.Password == sha1pass {
		return user, nil
	} else {
		return user, fmt.Errorf("Password does not match")
	}

}
