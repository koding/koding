package modelhelper

import (
	"koding/db/models"
	"koding/db/mongodb"
)

func GetAccountById(id string) (*models.Account, error) {
	account := new(models.Account)
	err := mongodb.One("jAccounts", id, account)
	if err != nil {
		return nil, err
	}

	return account, nil
}
