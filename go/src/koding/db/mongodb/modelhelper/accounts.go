package modelhelper

import (
	"koding/db/models"
	"strconv"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const AccountsColl = "jAccounts"

func GetAccountById(id string) (*models.Account, error) {
	account := new(models.Account)
	return account, Mongo.One(AccountsColl, id, account)
}

func GetAccount(username string) (*models.Account, error) {
	account := new(models.Account)
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": username}).One(&account)
	}
	return account, Mongo.Run(AccountsColl, query)
}

func GetAccountBySocialApiId(socialApiId int64) (*models.Account, error) {
	account := new(models.Account)
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{
			"socialApiId": strconv.FormatInt(socialApiId, 10),
		}).One(&account)
	}
	return account, Mongo.Run(AccountsColl, query)
}

func CheckAccountExistence(id string) (bool, error) {
	var exists bool
	query := checkExistence(id, &exists)
	return exists, Mongo.Run(AccountsColl, query)
}

func UpdateAccount(selector, options Selector) error {
	query := func(c *mgo.Collection) error {
		return c.Update(selector, options)
	}
	return Mongo.Run(AccountsColl, query)
}

// RemoveAccount removes given account
func RemoveAccount(id bson.ObjectId) error {
	return RemoveDocument(AccountsColl, id)
}

func RemoveAccountByUsername(username string) error {
	selector := bson.M{"profile": bson.M{"nickname": username}}

	query := func(c *mgo.Collection) error {
		err := c.Remove(selector)
		return err
	}

	return Mongo.Run(AccountsCollection, query)
}

func RemoveAllAccountByUsername(username string) error {
	selector := bson.M{"profile": bson.M{"nickname": username}}

	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(selector)
		return err
	}

	return Mongo.Run(AccountsCollection, query)
}

func CreateAccount(a *models.Account) error {
	query := insertQuery(a)
	return Mongo.Run(AccountsColl, query)
}
