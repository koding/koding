package plans

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/models"
	"koding/kites/kloud/contexthelper/session"
	"net/http"
	"net/url"
	"strings"
	"time"

	"golang.org/x/net/context"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type PaymentFetcher interface {
	Fetch(ctx context.Context, username string) (*PaymentResponse, error)
}

type CheckerFetcher interface {
	Fetch(ctx context.Context, plan string) (Checker, error)
}

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

type PaymentResponse struct {
	Plan  string
	State string
}

type Payment struct {
	PaymentEndpoint string
}

func (p *Payment) Fetch(ctx context.Context, username string) (*PaymentResponse, error) {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("Payment fetcher couldn't obtain session context")
	}

	if p.PaymentEndpoint == "" {
		return nil, errors.New("Payment endpoint is not set")
	}

	userEndpoint, err := url.Parse(p.PaymentEndpoint)
	if err != nil {
		return nil, err
	}

	var account *models.Account
	if err := sess.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Find(bson.M{"profile.nickname": username}).One(&account)
	}); err != nil {
		return nil, err
	}

	q := userEndpoint.Query()
	q.Set("account_id", account.Id.Hex())
	userEndpoint.RawQuery = q.Encode()

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
			return nil, fmt.Errorf("could not fetch subscription. err: '%s'", subscription.Description)
		}

		return nil, fmt.Errorf("could not fetch subscription. status code: %d", resp.StatusCode)
	}

	return &PaymentResponse{
		Plan:  strings.ToLower(subscription.PlanTitle),
		State: subscription.State,
	}, nil
}
