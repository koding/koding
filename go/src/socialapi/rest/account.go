package rest

import "socialapi/models"

func CreateAccount(a *models.Account) (*models.Account, error) {
	acc, err := sendModel("POST", "/account", a)
	if err != nil {
		return nil, err
	}

	return acc.(*models.Account), nil
}
