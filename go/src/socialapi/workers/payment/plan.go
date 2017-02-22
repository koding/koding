package payment

import (
	"socialapi/config"

	stripe "github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/currency"
	stripeplan "github.com/stripe/stripe-go/plan"
)

// TrialPeriod: Specifies a trial period in (an integer number of) days. If you
// include a trial period, the customer won’t be billed for the first time until
// the trial period ends. If the customer cancels before the trial period is
// over, she’ll never be billed at all.

const (
	// planPrefix       = "p_"
	customPlanPrefix = "p_c_"

	Free    = "p_free"
	Solo    = "p_solo"
	General = "p_general"
)

// plans holds koding provided plans on stripe
var plans = map[string]*stripe.PlanParams{
	// Forever free koding
	Free: {
		Amount:        0,
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   0,
		Name:          "Free User",
		Currency:      currency.USD,
		ID:            Free,
		Statement:     "FREE",
	},

	Solo: {
		Amount:        100, // 1$
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   30,
		Name:          "Solo User",
		Currency:      currency.USD,
		ID:            Solo,
		Statement:     "SOLO",
	},

	General: {
		Amount:        990, // 9.9$
		Interval:      stripeplan.Month,
		IntervalCount: 1,
		TrialPeriod:   30,
		Name:          "General User",
		Currency:      currency.USD,
		ID:            General,
		Statement:     "GENERAL",
	},
}

// GetPlan returns the plan by its name. User should check for existence.
func GetPlan(name string) *stripe.PlanParams {
	return plans[name]
}

// GetPlanID returns id of the plan according to the give user count
func GetPlanID(userCount int) string {
	switch {
	case userCount == 0:
		return GetPlan(Free).ID
	case userCount == 1:
		return GetPlan(Solo).ID
	default:
		return GetPlan(General).ID
	}
}

// CreateDefaultPlans creates predefined default plans. This is meant to be run
// when the worker starts to be sure the plans are there.
func CreateDefaultPlans() error {
	for _, plan := range plans {
		if err := EnsurePlan(plan); err != nil {
			return err
		}
	}
	return nil
}

// EnsurePlan makes sure plan is in stripe
func EnsurePlan(planParams *stripe.PlanParams) error {
	p, err := stripeplan.Get(planParams.ID, nil)
	if err == nil && p != nil && p.ID == planParams.ID {
		return nil
	}

	stripeErr, ok := err.(*stripe.Error)
	if !ok {
		return err
	}

	if stripeErr.Type != stripe.ErrorTypeInvalidRequest {
		return err
	}

	_, err = stripeplan.New(planParams)
	return err
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
