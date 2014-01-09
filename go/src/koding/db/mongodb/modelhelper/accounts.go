package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"

	"labix.org/v2/mgo"
)

func GetAccountById(id string) (*models.Account, error) {
	account := new(models.Account)
	return account, mongodb.One("jAccounts", id, account)
}

func CheckAccountExistence(id string) (bool, error) {
	var exists bool
	query := checkExistence(id, &exists)
	return exists, mongodb.Run("jAccounts", query)
}

func UpdateAccount(selector, options Selector) error {
	query := func(c *mgo.Collection) error {
		return c.Update(selector, options)
	}
	return mongodb.Run("jAccounts", query)
}
