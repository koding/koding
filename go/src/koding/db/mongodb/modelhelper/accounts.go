package modelhelper

import (
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const AccountsCollection = "jAccounts"

func GetAccountById(id string) (*models.Account, error) {
	account := new(models.Account)
	return account, Mongo.One(AccountsCollection, id, account)
}

func GetAccount(username string) (*models.Account, error) {
	account := new(models.Account)
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": username}).One(&account)
	}
	return account, Mongo.Run(AccountsCollection, query)
}

func CheckAccountExistence(id string) (bool, error) {
	var exists bool
	query := checkExistence(id, &exists)
	return exists, Mongo.Run("jAccounts", query)
}

func UpdateAccount(selector, options Selector) error {
	query := func(c *mgo.Collection) error {
		return c.Update(selector, options)
	}
	return Mongo.Run("jAccounts", query)
}

// RemoveAccount removes given account
func RemoveAccount(id bson.ObjectId) error {
	return RemoveDocument("jAccounts", id)
}
