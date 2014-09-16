package stripe

import (
	"errors"
	"socialapi/models/paymentmodel"

	"github.com/stripe/stripe-go"
	stripeCustomer "github.com/stripe/stripe-go/customer"
	stripePlan "github.com/stripe/stripe-go/plan"
	stripeSub "github.com/stripe/stripe-go/sub"
)

var (
	ProviderName = "stripe"
)

func init() {
	stripe.Key = "sk_test_VSkGDktXmmxl0MvXajOBxYGm"
}

//----------------------------------------------------------
// Customer
//----------------------------------------------------------

func CreateCustomer(username, email string) (*paymentmodel.Customer, error) {
	params := &stripe.CustomerParams{
		Desc:  username,
		Email: email,
	}

	stripeCustomer, err := stripeCustomer.Create(params)
	if err != nil {
		return nil, err
	}

	customerModel := paymentmodel.NewCustomer(
		username, stripeCustomer.Id, ProviderName,
	)

	err = customerModel.Create()
	if err != nil {
		return nil, err
	}

	return customerModel, nil
}

func FindCustomerByUsername(username string) (*paymentmodel.Customer, error) {
	customerModel := &paymentmodel.Customer{
		Username: username,
	}

	exists, err := customerModel.ByUserName()
	if err != nil {
		return nil, err
	}

	if !exists {
		return nil, nil
	}

	return customerModel, nil
}

//----------------------------------------------------------
// Plan
//----------------------------------------------------------

var ErrPlanAlreadyExists = errors.New(
	`{"type":"invalid_request_error","message":"Plan already exists."}`,
)

func CreateDefaultPlans() error {
	for plan_id, plan := range DefaultPlans {
		_, err := CreatePlan(plan_id, plan.Name, plan.Interval, plan.Amount)
		if err != nil {
			return err
		}
	}

	return nil
}

func CreatePlan(id, name string, interval stripe.PlanInternval, amount uint64) (*paymentmodel.Plan, error) {
	planParams := &stripe.PlanParams{
		Id:       id,
		Name:     name,
		Amount:   amount,
		Currency: stripe.USD,
		Interval: interval,
	}

	plan, err := stripePlan.Create(planParams)
	if err != nil && err.Error() != ErrPlanAlreadyExists.Error() {
		return nil, err
	}

	planModel := &paymentmodel.Plan{
		Name:           id,
		ProviderPlanId: plan.Id,
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

func FindPlanByName(name string) (*paymentmodel.Plan, error) {
	planModel := &paymentmodel.Plan{
		Name: name,
	}

	exists, err := planModel.ByName()
	if err != nil {
		return nil, err
	}

	if !exists {
		return nil, nil
	}

	return planModel, nil
}

//----------------------------------------------------------
// Subscription
//----------------------------------------------------------

func CreateSubscription(plan *paymentmodel.Plan, customer *paymentmodel.Customer) (*paymentmodel.Subscription, error) {
	subParams := &stripe.SubParams{
		Plan:     plan.ProviderPlanId,
		Customer: customer.ProviderCustomerId,
	}

	sub, err := stripeSub.Create(subParams)
	if err != nil {
		return nil, err
	}

	subModel := paymentmodel.NewSubscription(sub.Id, ProviderName, plan, customer)
	err = subModel.Create()
	if err != nil {
		return nil, err
	}

	return subModel, nil
}
