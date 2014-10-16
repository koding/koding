package paymentmodel

import (
	"errors"
	"time"

	"github.com/koding/bongo"
)

type Plan struct {
	Id int64 `json:"id,string"`

	// Id of plan in 3rd payment provider like Stripe.
	ProviderPlanId string `json:"providerPlanId"`

	// Name of provider. Enum:
	//		'stripe', 'paypal'
	Provider string `json:"provider"`

	// Duration of subscription. Enum:
	//    'monthly', 'yearly'
	Interval string `json:"interval"`

	// Title of plan. Enum:
	//		'free', 'hobbyist', 'developer', 'professional', 'super
	Title string `json:"title, string"`

	// Cost of plan in cents.
	AmountInCents uint64 `json:"amountInCents"`

	// Timestamps.
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt" `
	DeletedAt time.Time `json:"deletedAt"`
}

var (
	ErrTitleNotSet    = errors.New("title not set")
	ErrIntervalNotSet = errors.New("interval not set")
)

func (p *Plan) ByProviderId(providerId, provider string) error {
	selector := map[string]interface{}{
		"provider_plan_id": providerId,
		"provider":         provider,
	}

	err := p.Find(selector)
	return err
}

func (p *Plan) ByTitleAndInterval(title, interval string) error {
	selector := map[string]interface{}{
		"title":    title,
		"interval": interval,
	}

	err := p.One(bongo.NewQS(selector))
	return err
}

func (p *Plan) Find(selector map[string]interface{}) error {
	err := p.One(bongo.NewQS(selector))
	return err
}
