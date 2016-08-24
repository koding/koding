package payment

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"strings"

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
	FreeForever   = "p_free_forever"
	FreeFor7Days  = "p_free_for_7_days"
	FreeFor30Days = "p_free_for_30_days"
	UpTo10Users   = "p_up_to_10"
	UpTo50Users   = "p_up_to_50"
	Over50Users   = "p_over_50"
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

	// 7 days free koding
	FreeFor7Days: &stripe.PlanParams{
		Amount:        0,
		Interval:      stripeplan.Week,
		IntervalCount: 1,
		TrialPeriod:   7,
		Name:          "Free For 7 days",
		Currency:      currency.USD,
		ID:            FreeFor7Days,
		Statement:     "FREE FOR 7 DAYS",
	},

	// 30 days free koding
	FreeFor30Days: &stripe.PlanParams{
		Amount:        0,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   30,
		Name:          "Free For 30 days",
		Currency:      currency.USD,
		ID:            FreeFor30Days,
		Statement:     "FREE FOR 30 DAYS",
	},

	UpTo10Users: &stripe.PlanParams{
		Amount:        4997,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   0,
		Name:          "Up to 10 users",
		Currency:      currency.USD,
		ID:            UpTo10Users,
		Statement:     "UP TO 10 USERS",
	},

	UpTo50Users: &stripe.PlanParams{
		Amount:        3997,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   0,
		Name:          "Up to 50 users",
		Currency:      currency.USD,
		ID:            "p_up_to_50",
		Statement:     "UP TO 50 USERS",
	},

	Over50Users: &stripe.PlanParams{
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
	if conf.Debug {
		stripe.LogLevel = 3
	}
	go CreateDefaultPlans()
	go modelhelper.EnsureDeletedMemberIndex()
	return nil
}
