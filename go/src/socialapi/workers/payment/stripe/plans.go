package stripe

import "github.com/stripe/stripe-go"

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
		Amount:   9720,
		Interval: stripe.Year,
	},
	"developer_month": &Plan{
		Name:     "Developer",
		Amount:   1900,
		Interval: stripe.Month,
	},
	"developer_year": &Plan{
		Name:     "Developer",
		Amount:   20520,
		Interval: stripe.Year,
	},
	"professional_month": &Plan{
		Name:     "Professional",
		Amount:   3900,
		Interval: stripe.Month,
	},
	"professional_year": &Plan{
		Name:     "Professional",
		Amount:   42120,
		Interval: stripe.Year,
	},
}
