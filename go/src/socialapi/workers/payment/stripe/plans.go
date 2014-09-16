package stripe

import "github.com/stripe/stripe-go"

type Plan struct {
	NameForStripe string
	Amount        uint64
	Interval      stripe.PlanInternval
}

// Predefined list of plans. There are currently 4 tiers:
// "free", "hobbyist", "developer" and "professional" and 2
// intervals: "month" and "year".
var DefaultPlans = map[string]*Plan{
	"free_month": &Plan{
		NameForStripe: "Free",
		Amount:        0,
		Interval:      stripe.Month,
	},
	"free_year": &Plan{
		NameForStripe: "Free",
		Amount:        0,
		Interval:      stripe.Year,
	},
	"hobbyist_month": &Plan{
		NameForStripe: "Hobbyist",
		Amount:        900,
		Interval:      stripe.Month,
	},
	"hobbyist_year": &Plan{
		NameForStripe: "Hobbyist",
		Amount:        9720,
		Interval:      stripe.Year,
	},
	"developer_month": &Plan{
		NameForStripe: "Developer",
		Amount:        1900,
		Interval:      stripe.Month,
	},
	"developer_year": &Plan{
		NameForStripe: "Developer",
		Amount:        20520,
		Interval:      stripe.Year,
	},
	"professional_month": &Plan{
		NameForStripe: "Professional",
		Amount:        3900,
		Interval:      stripe.Month,
	},
	"professional_year": &Plan{
		NameForStripe: "Professional",
		Amount:        42120,
		Interval:      stripe.Year,
	},
}
