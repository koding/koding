package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"log"
	"net/http"
)

var (
	PlanUrl = "http://localhost:7000/payments/subscriptions"
)

var ExemptUsers = []interface{}{
	"sent-hil",
}

// checks if user is exempt from metric checkers, if something goes
// wrong while checking, we return true as a precaution
func exemptFromStopping(metricName, username string) (bool, error) {
	plan, err := getPlanForUser(username)
	if err != nil {
		log.Println(err)
		return true, err
	}

	if plan != "free" {
		return true, nil
	}

	isExempt, err := storage.ExemptGet(metricName, username)
	if err != nil {
		log.Println(err)
		return true, err
	}

	if isExempt {
		return true, nil
	}

	return false, nil
}

var (
	FreePlan = "free"
	PaidPlan = "paid"
)

func getPlanForUser(username string) (string, error) {
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return "", err
	}

	url := fmt.Sprintf("%s?account_id=%s", PlanUrl, account.Id.Hex())
	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}

	var subscription *SubscriptionResponse
	e := json.NewDecoder(resp.Body)
	if err := e.Decode(&subscription); err != nil {
		return "", err
	}

	if resp.StatusCode != 200 {
		return "", errors.New("response status not 200")
	}

	switch subscription.PlanTitle {
	case FreePlan:
		return FreePlan, nil
	default:
		return PaidPlan, nil
	}
}

type SubscriptionResponse struct {
	PlanTitle string `json:"planTitle"`
}
