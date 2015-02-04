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
	DefaultPlanUrl = "http://localhost:7000/payments"
	FreePlanName   = "free"
)

type Client struct {
	PlanUrl       string
	DefaultToPaid bool
}

func New(planUrl string) *Client {
	if planUrl == "" {
		planUrl = DefaultPlanUrl
	}

	return &Client{
		PlanUrl:       planUrl,
		DefaultToPaid: true,
	}
}

func (c *Client) IsPaidAccount(account *models.Account) (bool, error) {
	sub, err := c.GetByAccount(account)
	if err != nil {
		return false, err
	}

	return sub.PlanTitle != FreePlanName, nil
}

func (c *Client) GetByUsername(username string) (*payment.SubscriptionsResponse, error) {
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return nil, err
	}

	return c.GetByAccount(account)
}

func (c *Client) GetByAccountId(accountId string) (*payment.SubscriptionsResponse, error) {
	account, err := modelhelper.GetAccountById(accountId)
	if err != nil {
		return nil, err
	}

	return c.GetByAccount(account)
}

func (c *Client) GetByAccount(account *models.Account) (*payment.SubscriptionsResponse, error) {
	url := fmt.Sprintf("%s?account_id=%s", c.PlanUrl, account.Id.Hex())
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
