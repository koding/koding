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

var (
	UserColl              = "jUsers"
	UserStatusConfirmed   = "confirmed"
	UserStatusUnConfirmed = "unconfirmed"
	UserStatusBlocked     = "blocked"
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

	err := Mongo.Run(UserColl, query)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func GetUsersById(ids ...bson.ObjectId) ([]*models.User, error) {
	var users []*models.User
	if err := Mongo.Run("jUsers", func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": ids}}).All(&users)
	}); err != nil {
		return nil, fmt.Errorf("jUsers lookup error: %v", err)
	}

	return users, nil
}

func GetUserById(id string) (*models.User, error) {
	user := new(models.User)
	err := Mongo.One(UserColl, id, user)
	if err != nil {
		return nil, err
	}

	return user, nil
}

func GetAccountByUserId(id bson.ObjectId) (*models.Account, error) {
	user := new(models.User)
	err := Mongo.One(UserColl, id.Hex(), user)
	if err != nil {
		return nil, err
	}

	return GetAccount(user.Name)
}

func GetSomeUsersBySelector(s Selector) ([]models.User, error) {
	users := make([]models.User, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(s).Iter()

		var user models.User
		for iter.Next(&user) {
			users = append(users, user)
		}

		return iter.Close()
	}

	return users, Mongo.Run(UserColl, query)
}

func CreateUser(a *models.User) error {
	query := insertQuery(a)
	return Mongo.Run(UserColl, query)
}

func UpdateEmailFrequency(username string, e models.EmailFrequency) error {
	selector := bson.M{"username": username}
	updateQuery := bson.M{"$set": bson.M{"emailFrequency": e}}

	query := func(c *mgo.Collection) error {
		_, err := c.UpdateAll(selector, updateQuery)
		return err
	}

	return Mongo.Run(UserColl, query)
}

// FetchUserByEmail fetches user from db according to given email
func FetchUserByEmail(email string) (*models.User, error) {
	user := &models.User{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"email": email}).One(&user)
	}
	return user, Mongo.Run(UserColl, query)
}

func BlockUser(username, reason string, duration time.Duration) error {
	selector := bson.M{"username": username}
	updateQuery := bson.M{"$set": bson.M{
		"status":        UserStatusBlocked,
		"blockedReason": reason, "blockedUntil": time.Now().UTC().Add(duration),
	}}

	query := func(c *mgo.Collection) error {
		err := c.Update(selector, updateQuery)
		return err
	}

	return Mongo.Run(UserColl, query)
}

func RemoveUser(username string) error {
	selector := bson.M{"username": username}

	query := func(c *mgo.Collection) error {
		err := c.Remove(selector)
		return err
	}

	return Mongo.Run(UserColl, query)
}

func RemoveAllUsers(username string) error {
	selector := bson.M{"username": username}

	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(selector)
		return err
	}

	return Mongo.Run(UserColl, query)
}

func GetUserByAccountId(id string) (*models.User, error) {
	account, err := GetAccountById(id)
	if err != nil {
		return nil, err
	}

	return GetUser(account.Profile.Nickname)
}

func UpdateUser(selector, update bson.M) error {
	query := func(c *mgo.Collection) error {
		err := c.Update(selector, bson.M{"$set": update})
		return err
	}

	return Mongo.Run(UserColl, query)
}
