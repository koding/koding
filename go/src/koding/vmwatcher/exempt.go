package main

import (
	"encoding/json"
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

func getPlanForUser(username string) (string, error) {
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return "", err
	}

	url := fmt.Sprintf("%s?account_id=%s", PlanUrl, account.Id)
	resp, err := http.Get(url)
	if err != nil {
		return "", nil
	}

	var subscription *SubscriptionResponse
	e := json.NewDecoder(resp.Body)
	if err := e.Decode(&subscription); err != nil {
		return "", nil
	}

	if resp.StatusCode != 200 {
		return "", nil
	}

	return subscription.PlanTitle, nil
}

type SubscriptionResponse struct {
	PlanTitle string `json:"planTitle"`
}
