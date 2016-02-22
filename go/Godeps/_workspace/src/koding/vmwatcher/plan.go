package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net/http"
)

var (
	PlanUrl  = "http://localhost:7000/payments/subscriptions"
	FreePlan = "free"
	PaidPlan = "paid"
)

type SubscriptionResponse struct {
	PlanTitle string `json:"planTitle"`
}

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

	defer resp.Body.Close()

	var subscription *SubscriptionResponse
	e := json.NewDecoder(resp.Body)
	if err := e.Decode(&subscription); err != nil {
		return "", err
	}

	if resp.StatusCode != 200 {
		return "", errors.New("response status not 200")
	}

	// there are 2 tiers: free and paid; all paid users get same quota
	switch subscription.PlanTitle {
	case FreePlan:
		return FreePlan, nil
	default:
		return PaidPlan, nil
	}
}
