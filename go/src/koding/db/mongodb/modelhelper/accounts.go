package modelhelper

import (
	"koding/db/models"
	"strconv"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const AccountsColl = "jAccounts"

func GetAccountById(id string) (*models.Account, error) {
	account := new(models.Account)
	return account, Mongo.One(AccountsColl, id, account)
}

// GetAccountsByIds fetches all the accounts given by their IDs
func GetAccountsByIds(ids []bson.ObjectId) ([]models.Account, error) {
	accounts := make([]models.Account, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": ids}}).All(&accounts)
	}

	return accounts, Mongo.Run(AccountsColl, query)
}

func GetAccount(username string) (*models.Account, error) {
	var account models.Account

	if err := getAccount(username, &account); err != nil {
		return nil, err
	}

	return &account, nil
}

func GetAccountID(username string) (bson.ObjectId, error) {
	var account struct {
		ID bson.ObjectId `bson:"_id"`
	}

	if err := getAccount(username, &account); err != nil {
		return "", err
	}

	return account.ID, nil
}

func getAccount(username string, out interface{}) error {
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": username}).One(out)
	}
	return Mongo.Run(AccountsColl, query)
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

// GetAccountBySocialApiIds fetches the accounts by their socialApiIds
func GetAccountBySocialApiIds(socialApiIds ...string) ([]models.Account, error) {
	accounts := make([]models.Account, 0)
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"socialApiId": bson.M{"$in": socialApiIds}}).All(&accounts)
	}
	return accounts, Mongo.Run(AccountsColl, query)
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
		return c.Remove(selector)
	}

	return Mongo.Run(AccountsColl, query)
}

func RemoveAllAccountByUsername(username string) error {
	selector := bson.M{"profile": bson.M{"nickname": username}}

	query := func(c *mgo.Collection) error {
		_, err := c.RemoveAll(selector)
		return err
	}

	return Mongo.Run(AccountsColl, query)
}

func CreateAccount(a *models.Account) error {
	query := insertQuery(a)
	return Mongo.Run(AccountsColl, query)
}
