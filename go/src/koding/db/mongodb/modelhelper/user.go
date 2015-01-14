package modelhelper

import (
	"crypto/sha1"
	"encoding/hex"
	"fmt"
	"koding/db/models"
	"time"

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

	err := Mongo.Run("jUsers", query)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func GetUserById(id string) (*models.User, error) {
	user := new(models.User)
	err := Mongo.One("jUsers", id, user)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func GetSomeUsersBySelector(s Selector) ([]models.User, error) {
	users := make([]models.User, 0)
	query := func(c *mgo.Collection) error {
		return c.Find(s).All(&users)
	}

	return users, Mongo.Run("jUsers", query)
}

func CreateUser(a *models.User) error {
	query := insertQuery(a)
	return Mongo.Run("jUsers", query)
}

func UpdateEmailFrequency(username string, e models.EmailFrequency) error {
	selector := bson.M{"username": username}
	updateQuery := bson.M{"$set": bson.M{"emailFrequency": e}}

	query := func(c *mgo.Collection) error {
		_, err := c.UpdateAll(selector, updateQuery)
		return err
	}

	return Mongo.Run("jUsers", query)
}

var (
	UserStatusConfirmed   = "confirmed"
	UserStatusUnConfirmed = "unconfirmed"
	UserStatusBlocked     = "blocked"
)

func BlockUser(username, reason string, duration time.Duration) error {
	selector := bson.M{"username": username}
	updateQuery := bson.M{"$set": bson.M{
		"status":        UserStatusBlocked,
		"blockedReason": reason, "blockedUntil": time.Now().Add(duration),
	}}

	query := func(c *mgo.Collection) error {
		err := c.Update(selector, updateQuery)
		return err
	}

	return Mongo.Run("jUsers", query)
}

func RemoveUser(username string) error {
	selector := bson.M{"username": username}

	query := func(c *mgo.Collection) error {
		err := c.Remove(selector)
		return err
	}

	return Mongo.Run("jUsers", query)
}
