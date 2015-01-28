package paymentapi

import (
	"encoding/json"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"socialapi/workers/payment"
)

var (
	// TODO: get from config
	PlanUrl = "http://localhost:7000/payments"

	FreePlanName = "free"
)

func IsPaidAccount(account *models.Account) (bool, error) {
	sub, err := GetByAccount(account)
	if err != nil {
		return false, err
	}

	return sub.PlanTitle != FreePlanName, nil
}

func GetByUsername(username string) (*payment.SubscriptionsResponse, error) {
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return nil, err
	}

	return GetByAccount(account)
}

func GetByAccountId(accountId string) (*payment.SubscriptionsResponse, error) {
	account, err := modelhelper.GetAccountById(accountId)
	if err != nil {
		return nil, err
	}

	return GetByAccount(account)
}

func GetByAccount(account *models.Account) (*payment.SubscriptionsResponse, error) {
	url := fmt.Sprintf("%s?account_id=%s", PlanUrl, account.Id.Hex())
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}

	var subscription *payment.SubscriptionsResponse
	e := json.NewDecoder(resp.Body)
	if err := e.Decode(&subscription); err != nil {
		return nil, err
	}

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("response status not 200, was %d", resp.StatusCode)
	}

	return subscription, nil
}
