package rest

import (
	"fmt"
	"socialapi/models"
)

func MarkAsTroll(account *models.Account) error {
	url := fmt.Sprintf("/trollmode/%d", account.Id)
	_, err := sendModel("POST", url, account)
	return err
}

func UnMarkAsTroll(account *models.Account) error {
	url := fmt.Sprintf("/trollmode/%d", account.Id)
	_, err := sendRequest("DELETE", url, nil)
	return err
}
