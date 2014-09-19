package stripe

import "github.com/stripe/stripe-go"

type Plan struct {
	Title, NameForStripe string
	Amount               uint64
	Interval             stripe.PlanInternval
}

// Predefined list of plans. There are currently 5 tiers:
// "free", "hobbyist", "developer", "professional" "super"
// and 2 intervals: "month" and "year".
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
		Amount:        995,
		Interval:      stripe.Month,
	},
	"hobbyist_year": &Plan{
		Title:         "hobbyist",
		NameForStripe: "Hobbyist",
		Amount:        10746,
		Interval:      stripe.Year,
	},
	"developer_month": &Plan{
		Title:         "developer",
		NameForStripe: "Developer",
		Amount:        1995,
		Interval:      stripe.Month,
	},
	"developer_year": &Plan{
		Title:         "developer",
		NameForStripe: "Developer",
		Amount:        21546,
		Interval:      stripe.Year,
	},
	"professional_month": &Plan{
		Title:         "professional",
		NameForStripe: "Professional",
		Amount:        4995,
		Interval:      stripe.Month,
	},
	"professional_year": &Plan{
		Title:         "professional",
		NameForStripe: "Professional",
		Amount:        53946,
		Interval:      stripe.Year,
	},
	"super_month": &Plan{
		Title:         "super",
		NameForStripe: "Super",
		Amount:        9995,
		Interval:      stripe.Month,
	},
	"super_year": &Plan{
		Title:         "super",
		NameForStripe: "Super",
		Amount:        107946,
		Interval:      stripe.Year,
	},
}
