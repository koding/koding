package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const AccountsCollection = "jAccounts"

func GetAccountById(id string) (*models.Account, error) {
	account := new(models.Account)
	err := mongodb.One(AccountsCollection, id, account)
	if err != nil {
		return nil, err
	}

	return account, nil
}

func GetAccount(username string) (*models.Account, error) {
	account := new(models.Account)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": username}).One(&account)
	}

	err := mongodb.Run(AccountsCollection, query)
	if err != nil {
		return nil, err
	}

	return account, nil
}
