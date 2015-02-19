package koding

import (
	"encoding/json"
	"fmt"
	"koding/db/models"
	"koding/kites/kloud/protocol"
	"net/http"
	"net/url"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type SubscriptionsResponse struct {
	AccountId          string    `json:"accountId"`
	PlanTitle          string    `json:"planTitle"`
	PlanInterval       string    `json:"planInterval"`
	State              string    `json:"state"`
	CurrentPeriodStart time.Time `json:"currentPeriodStart"`
	CurrentPeriodEnd   time.Time `json:"currentPeriodEnd"`
	Description        string    `json:"description"`
	Error              string    `json:"error"`
}

type FetcherResponse struct {
	Plan  Plan
	State string
}

func (p *Provider) Fetcher(m *protocol.Machine) (fetcherResp *FetcherResponse, planErr error) {
	defer func() {
		if planErr != nil {
			p.Log.Warning("[%s] username: %s could not fetch plan. Fallback to Free plan. err: '%s'",
				m.Id, m.Username, planErr)

			fetcherResp = &FetcherResponse{Plan: Free}
			planErr = nil
		}
	}()

	userEndpoint, err := url.Parse(p.PaymentEndpoint)
	if err != nil {
		return nil, err
	}

	var account *models.Account
	if err := p.Session.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": m.Username}).One(&account)
	}); err != nil {
		return nil, err
	}

	q := userEndpoint.Query()
	q.Set("account_id", account.Id.Hex())
	userEndpoint.RawQuery = q.Encode()

	p.Log.Debug("[%s] fetching plan via URL: '%s'", m.Id, userEndpoint.String())
	resp, err := http.Get(userEndpoint.String())
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var subscription *SubscriptionsResponse
	e := json.NewDecoder(resp.Body)
	if err := e.Decode(&subscription); err != nil {
		return nil, err
	}

	// return an error back for a non 200 status
	if resp.StatusCode != 200 {
		if subscription.Error != "" {
			return nil, fmt.Errorf("[%s] could not fetch subscription. err: '%s'",
				m.Id, subscription.Description)
		}

		return nil, fmt.Errorf("[%s] could not fetch subscription. status code: %d",
			m.Id, resp.StatusCode)
	}

	plan, ok := plans[subscription.PlanTitle]
	if !ok {
		return nil, fmt.Errorf("[%s] could not find plan. There is no plan called '%s'",
			m.Id, subscription.PlanTitle)
	}

	return &FetcherResponse{
		Plan:  plan,
		State: subscription.State,
	}, nil
}
