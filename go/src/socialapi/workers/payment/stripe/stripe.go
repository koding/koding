package stripe

import (
	"errors"
	"socialapi/models/paymentmodel"

	"github.com/stripe/stripe-go"
	stripeCustomer "github.com/stripe/stripe-go/customer"
	stripePlan "github.com/stripe/stripe-go/plan"
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

type Plan struct {
	Name     string
	Amount   uint64
	Interval stripe.PlanInternval
}

var DefaultPlans = map[string]*Plan{
	"free_month": &Plan{
		Name:     "Free",
		Amount:   0,
		Interval: stripe.Month,
	},
	"free_year": &Plan{
		Name:     "Free",
		Amount:   0,
		Interval: stripe.Year,
	},
	"hobbyist_month": &Plan{
		Name:     "Hobbyist",
		Amount:   900,
		Interval: stripe.Month,
	},
	"hobbyist_year": &Plan{
		Name:     "Hobbyist",
		Amount:   900,
		Interval: stripe.Year,
	},
	"developer_month": &Plan{
		Name:     "Developer",
		Amount:   1900,
		Interval: stripe.Month,
	},
	"developer_year": &Plan{
		Name:     "Developer",
		Amount:   1900,
		Interval: stripe.Year,
	},
	"professional_month": &Plan{
		Name:     "Professional",
		Amount:   3900,
		Interval: stripe.Month,
	},
	"professional_year": &Plan{
		Name:     "Professional",
		Amount:   3900,
		Interval: stripe.Year,
	},
}

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
