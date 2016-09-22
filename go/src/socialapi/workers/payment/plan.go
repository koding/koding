package payment

import (
	"socialapi/config"

	stripe "github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/currency"
	stripeplan "github.com/stripe/stripe-go/plan"
)

// Up to 10 users:  $49.97 per developer per month
// Up to 50 users:  $39.97 per developer per month
// Over 50 users:  $34.97 per developer per month

// TrialPeriod: Specifies a trial period in (an integer number of) days. If you
// include a trial period, the customer won’t be billed for the first time until
// the trial period ends. If the customer cancels before the trial period is
// over, she’ll never be billed at all.

const (
	planPrefix       = "p_"
	customPlanPrefix = "p_c_"

	FreeForever = "p_free_forever"
	UpTo10Users = "p_up_to_10"
	UpTo50Users = "p_up_to_50"
	Over50Users = "p_over_50"
)

// Plans holds koding provided plans on stripe
var Plans = map[string]*stripe.PlanParams{
	// Forever free koding
	FreeForever: &stripe.PlanParams{
		Amount:        0,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   0,
		Name:          "Free Forever",
		Currency:      currency.USD,
		ID:            FreeForever,
		Statement:     "FREE",
	},

	UpTo10Users: &stripe.PlanParams{
		Amount:        4997,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   7,
		Name:          "Up to 10 users",
		Currency:      currency.USD,
		ID:            UpTo10Users,
		Statement:     "UP TO 10 USERS",
	},

	UpTo50Users: &stripe.PlanParams{
		Amount:        3997,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   7,
		Name:          "Up to 50 users",
		Currency:      currency.USD,
		ID:            UpTo50Users,
		Statement:     "UP TO 50 USERS",
	},

	Over50Users: &stripe.PlanParams{
		Amount:        3497,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   7,
		Name:          "Over 50 users",
		Currency:      currency.USD,
		ID:            Over50Users,
		Statement:     "OVER 50 USERS",
	},
}

// GetPlanID returns id of the plan according to the give user count
func GetPlanID(userCount int) string {
	if userCount < 10 {
		return Plans[UpTo10Users].ID
	}

	if userCount < 50 {
		return Plans[UpTo50Users].ID
	}

	return Plans[Over50Users].ID
}

// CreateDefaultPlans creates predefined default plans. This is meant to be run
// when the worker starts to be sure the plans are there.
func CreateDefaultPlans() error {
	for _, planParams := range Plans {
		p, err := stripeplan.Get(planParams.ID, nil)
		if err == nil && p != nil && p.ID == planParams.ID {
			continue
		}

		stripeErr, ok := err.(*stripe.Error)
		if !ok {
			return err
		}

		if stripeErr.Type != stripe.ErrorTypeInvalidRequest {
			return err
		}

		_, err = stripeplan.New(planParams)
		if err != nil {
			return err
		}
	}

	return nil
}

// Initialize inits the payment worker for further operations
func Initialize(conf *config.Config) error {
	stripe.Key = conf.Stripe.SecretToken
	if conf.Debug {
		stripe.LogLevel = 3
	}
	go CreateDefaultPlans()
	return nil
}
