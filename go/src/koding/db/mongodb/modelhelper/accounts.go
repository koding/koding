package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
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
