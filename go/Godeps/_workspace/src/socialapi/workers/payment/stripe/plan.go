package stripe

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/paymentplan"

	stripe "github.com/stripe/stripe-go"
	stripePlan "github.com/stripe/stripe-go/plan"
)

// CreateDefaultPlans creates predefined default plans. This is meant
// to be run when the worker starts to be sure the plans weren't
// deleted, not called during app runtime.
func CreateDefaultPlans() error {
	for id, pl := range paymentplan.DefaultPlans {
		plan, err := FindPlanByTitleAndInterval(pl.Title, pl.Interval.ToString())
		if err != nil && err != paymenterrors.ErrPlanNotFound {
			return err
		}

		if plan != nil {
			continue
		}

		_, err = CreatePlan(id, pl.Title, pl.NameForStripe, pl.Interval, pl.Amount)
		if err != nil {
			continue
		}
	}

	return nil
}

func getStripePlanInterval(i paymentplan.PlanInterval) stripe.PlanInternval {
	switch i.ToString() {
	case "month":
		return stripe.Month
	case "year":
		return stripe.Year
	}

	return stripe.Month
}

// CreatePlan creates plan in Stripe and saves it locally. It deals with
// cases where plan exists in stripe, but not locally.
func CreatePlan(id, title, nameForStripe string, interval paymentplan.PlanInterval, amount uint64) (*paymentmodels.Plan, error) {
	planParams := &stripe.PlanParams{
		Id:       id,
		Name:     nameForStripe,
		Amount:   amount,
		Currency: stripe.USD,
		Interval: getStripePlanInterval(interval),
	}

	_, err := stripePlan.New(planParams)
	if err != nil {
		err = handleStripeError(err)
		if !IsPlanAlredyExistsErr(err) {
			return nil, err
		}
	}

	planModel := &paymentmodels.Plan{
		Title:          title,
		ProviderPlanId: id,
		Provider:       ProviderName,
		Interval:       interval.ToString(),
		AmountInCents:  amount,
	}

	err = planModel.Create()

	return planModel, err
}

func FindPlanByTitleAndInterval(title, interval string) (*paymentmodels.Plan, error) {
	plan := paymentmodels.NewPlan()

	if err := plan.ByTitleAndInterval(title, interval); err != nil {
		if paymenterrors.IsPlanNotFoundErr(err) {
			return nil, paymenterrors.ErrPlanNotFound
		}

		return nil, err
	}

	return plan, nil
}
