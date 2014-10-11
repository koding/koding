package stripe

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"

	stripe "github.com/stripe/stripe-go"
	stripePlan "github.com/stripe/stripe-go/plan"
)

// CreateDefaultPlans creates predefined default plans. This is meant
// to be run when the worker starts to be sure the plans weren't
// deleted, not called during app runtime.
func CreateDefaultPlans() error {
	for id, pl := range DefaultPlans {
		plan, err := FindPlanByTitleAndInterval(pl.Title, string(pl.Interval))
		if err != nil && err != paymenterrors.ErrPlanNotFound {
			return err
		}

		if plan != nil {
			continue
		}

		_, err = CreatePlan(id, pl.Title, pl.NameForStripe, pl.Interval, pl.Amount)
		if err != nil {
			return err
		}
	}

	return nil
}

// CreatePlan creates plan in Stripe and saves it locally. It deals with
// cases where plan exists in stripe, but not locally.
func CreatePlan(id, title, nameForStripe string, interval stripe.PlanInternval, amount uint64) (*paymentmodel.Plan, error) {
	planParams := &stripe.PlanParams{
		Id:       id,
		Name:     nameForStripe,
		Amount:   amount,
		Currency: stripe.USD,
		Interval: interval,
	}

	_, err := stripePlan.New(planParams)
	if err != nil && err.Error() != ErrStripePlanAlreadyExists.Error() {
		return nil, handleStripeError(err)
	}

	planModel := &paymentmodel.Plan{
		Title:          title,
		ProviderPlanId: id,
		Provider:       ProviderName,
		Interval:       string(interval),
		AmountInCents:  amount,
	}

	err = planModel.Create()
	if err != nil {
		return nil, err
	}

	return planModel, nil
}

func FindPlanByTitleAndInterval(title, interval string) (*paymentmodel.Plan, error) {
	plan := &paymentmodel.Plan{
		Title:    title,
		Interval: interval,
	}

	exists, err := plan.ByTitleAndInterval()
	if err != nil {
		if paymenterrors.IsPlanNotFoundErr(err) {
			return nil, paymenterrors.ErrPlanNotFound
		}

		return nil, err
	}

	if !exists {
		return nil, paymenterrors.ErrPlanNotFound
	}

	return plan, nil
}
