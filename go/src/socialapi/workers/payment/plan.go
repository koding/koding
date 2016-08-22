package payment

import (
	"socialapi/config"
	"strings"

	stripe "github.com/stripe/stripe-go"
	stripeplan "github.com/stripe/stripe-go/plan"
	 "github.com/stripe/stripe-go/currency"
)

// Up to 10 users:  $49.97 per developer per month
// Up to 50 users:  $39.97 per developer per month
// Over 50 users:  $34.97 per developer per month


// TrialPeriod: Specifies a trial period in (an integer number of) days. If you
// include a trial period, the customer won’t be billed for the first time until
// the trial period ends. If the customer cancels before the trial period is
// over, she’ll never be billed at all.

// Plans holds koding provided plans on stripe
var Plans = []*stripe.PlanParams{
	// Forever free koding
	&stripe.PlanParams{
		Amount:        0,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   0,
		Name:          "Free Forever",
		Currency:      currency.USD,
		ID:            "p_free_forever",
		Statement:     "FREE",
	},

	// 7 days free koding
	&stripe.PlanParams{
		Amount:        0,
		Interval:      stripeplan.Week,
		IntervalCount: 1,
		TrialPeriod:   7,
		Name:          "Free For 7 days",
		Currency:      currency.USD,
		ID:            "p_free_for_7_days",
		Statement:     "FREE FOR 7 DAYS",
	},

	// 30 days free koding
	&stripe.PlanParams{
		Amount:        0,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   30,
		Name:          "Free For 30 days",
		Currency:      currency.USD,
		ID:            "p_free_for_30_days",
		Statement:     "FREE FOR 30 DAYS",
	},

	&stripe.PlanParams{
		Amount:        4997,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   0,
		Name:          "Up to 10 users",
		Currency:      currency.USD,
		ID:            "p_up_to_10",
		Statement:     "UP TO 10 USERS",
	},

	&stripe.PlanParams{
		Amount:        3997,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   0,
		Name:          "Up to 50 users",
		Currency:      currency.USD,
		ID:            "p_up_to_50",
		Statement:     "UP TO 50 USERS",
	},

	&stripe.PlanParams{
		Amount:        3497,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   0,
		Name:          "Over 50 users",
		Currency:      currency.USD,
		ID:            "p_over_50",
		Statement:     "OVER 50 USERS",
	},
}

// CreateDefaultPlans creates predefined default plans. This is meant to be run
// when the worker starts to be sure the plans are there.
func CreateDefaultPlans() error {
	for _, planParams := range Plans {
		p, err := stripeplan.Get(planParams.ID, nil)
		if err == nil && p != nil && p.ID == planParams.ID {
			continue
		}

		if _, err := stripeplan.New(planParams); err != nil {
			if strings.Contains(err.Error(), "already exists") {
				continue
			}

			return err
		}
	}

	return nil
}

// Initialize inits the payment worker for further operations 
func Initialize(conf *config.Config) error {
	stripe.Key = conf.Stripe.SecretToken
	go CreateDefaultPlans() // for now only default plan creation
	return nil
}
