package stripe

import "github.com/stripe/stripe-go"

type Plan struct {
	Title, NameForStripe string
	Amount               uint64
	Interval             stripe.PlanInternval
}

// Predefined list of plans. There are currently 4 tiers:
// "free", "hobbyist", "developer" and "professional" and 2
// intervals: "month" and "year".
var DefaultPlans = map[string]*Plan{
	"free_month": &Plan{
		Title:         "free",
		NameForStripe: "Free",
		Amount:        0,
		Interval:      stripe.Month,
	},
	"free_year": &Plan{
		Title:         "free",
		NameForStripe: "Free",
		Amount:        0,
		Interval:      stripe.Year,
	},
	"hobbyist_month": &Plan{
		Title:         "hobbyist",
		NameForStripe: "Hobbyist",
		Amount:        900,
		Interval:      stripe.Month,
	},
	"hobbyist_year": &Plan{
		Title:         "hobbyist",
		NameForStripe: "Hobbyist",
		Amount:        9720,
		Interval:      stripe.Year,
	},
	"developer_month": &Plan{
		Title:         "developer",
		NameForStripe: "Developer",
		Amount:        1900,
		Interval:      stripe.Month,
	},
	"developer_year": &Plan{
		Title:         "developer",
		NameForStripe: "Developer",
		Amount:        20520,
		Interval:      stripe.Year,
	},
	"professional_month": &Plan{
		Title:         "professional",
		NameForStripe: "Professional",
		Amount:        3900,
		Interval:      stripe.Month,
	},
	"professional_year": &Plan{
		Title:         "professional",
		NameForStripe: "Professional",
		Amount:        42120,
		Interval:      stripe.Year,
	},
}
