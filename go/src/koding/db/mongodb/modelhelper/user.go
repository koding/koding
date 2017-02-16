package modelhelper

import (
	"crypto/sha1"
	"encoding/hex"
	"errors"
	"fmt"
	"koding/db/models"
	"time"

	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const UserColl = "jUsers"

// ErrNotParticipant holds the error case where a user tries to login to a
// non-participated group
var ErrNotParticipant = errors.New("not a participant of group")

// CheckAndGetUser validates the user with the given password. If not
// successful it returns nil
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

var userOnlyID = bson.M{
	"_id": 1,
}

func GetUserID(username string) (bson.ObjectId, error) {
	var id struct {
		ID bson.ObjectId `bson:"_id"`
	}

	fn := func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).Select(userOnlyID).One(&id)
	}

	if err := Mongo.Run(UserColl, fn); err != nil {
		return "", err
	}

	return id.ID, nil
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

// GetAnySlackTokenWithGroup checks the slack token of users if does exits or not
func GetAnySlackTokenWithGroup(groupName string) ([]models.User, error) {
	var users []models.User

	key := fmt.Sprintf("foreignAuth.slack.%s.token", groupName)

	selector := Selector{key: bson.M{"$exists": true}}

	users, err := GetSomeUsersBySelector(selector)
	if err != nil {
		return nil, err
	}

	return users, nil
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
		"status":        models.UserBlocked,
		"blockedReason": reason, "blockedUntil": time.Now().UTC().Add(duration),
	}}

	query := func(c *mgo.Collection) error {
		err := c.Update(selector, updateQuery)
		return err
	}

	return Mongo.Run(UserColl, query)
}

func UserStatus(username string) (models.UserStatus, error) {
	var status struct {
		Status string `bson:"status"`
	}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).One(&status)
	}

	if err := Mongo.Run(UserColl, query); err != nil {
		return "", err
	}

	if status.Status == "" {
		return "", mgo.ErrNotFound
	}

	return models.UserStatus(status.Status), nil
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
		return c.Update(selector, bson.M{"$set": update})
	}

	return Mongo.Run(UserColl, query)
}

func GetUserByQuery(selector bson.M) (*models.User, error) {
	var user *models.User

	query := func(c *mgo.Collection) error {
		return c.Find(selector).One(&user)
	}

	return user, Mongo.Run(UserColl, query)
}

func CountUsersByQuery(selector bson.M) (int, error) {
	var count int
	var err error

	var query = func(c *mgo.Collection) error {
		count, err = c.Find(selector).Count()
		return err
	}

	return count, Mongo.Run(UserColl, query)
}

// GetPermittedUser returns the permitted user of the machine (owner or shared
// user), if it's not found it returns an error. The requestName is optional,
// if it's not empty and the the users list has more than one valid allowed
// users, we return the one that matches the requesterName.
func GetPermittedUser(requesterName string, users []models.MachineUser) (*models.User, error) {
	allowedIds := make([]bson.ObjectId, 0)
	for _, perm := range users {
		// owner is allowed to do anything
		if perm.Owner {
			allowedIds = append(allowedIds, perm.Id)
			continue
		}

		// for this requestername needs to be available, for owner we don't care
		if (perm.Permanent && perm.Approved) && requesterName != "" {
			allowedIds = append(allowedIds, perm.Id)

		}
	}

	// nothing found, just return
	if len(allowedIds) == 0 {
		return nil, errors.New("owner not found")
	}

	// if the list contains only one user and if the requesterName is empty,
	// just get the do a short lookup and return the first result. (usually if
	// there is only one owner)
	if len(allowedIds) == 1 || requesterName == "" {
		var user *models.User
		err := Mongo.Run("jUsers", func(c *mgo.Collection) error {
			return c.FindId(allowedIds[0]).One(&user)
		})

		if err == mgo.ErrNotFound {
			return nil, fmt.Errorf("User with Id not found: %s", allowedIds[0].Hex())
		}
		if err != nil {
			return nil, fmt.Errorf("username lookup error: %v", err)
		}

		return user, nil
	}

	// get the full list of users and return the one that matches the
	// requesterName, if not we return someone that is allowed. Note that we
	// don't do the validation here, this is only to fetch the user, don't put
	// any validation logic here.
	var allowedUsers []*models.User
	if err := Mongo.Run("jUsers", func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": allowedIds}}).All(&allowedUsers)
	}); err != nil {
		return nil, fmt.Errorf("username lookup error: %s", err)
	}

	// now we have all allowed users, if we have someone that is in match with
	// the requesterName just return it.
	for _, u := range allowedUsers {
		if u.Name == requesterName {
			return u, nil
		}
	}

	// nothing found, just return the first one
	return allowedUsers[0], nil
}

// UserLogin checks if the given username is participant of the given group. On
// successful validation returns a session for the user in the context of the
// given group.
//
// There are multiple ways to login in Koding but does not hadle all the cases.
// For other custom logic use, webserver's login handler.
func UserLogin(username, groupName string) (*models.Session, error) {
	isMember, err := IsParticipant(username, groupName)
	if err != nil {
		return nil, err
	}

	if !isMember {
		return nil, ErrNotParticipant
	}

	return FetchOrCreateSession(username, groupName)
}
