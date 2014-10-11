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
		NameForStripe: "Hobbyist Monthy",
		Amount:        1250,
		Interval:      stripe.Month,
	},
	"hobbyist_year": &Plan{
		Title:         "hobbyist",
		NameForStripe: "Hobbyist Yearly",
		Amount:        11940,
		Interval:      stripe.Year,
	},
	"developer_month": &Plan{
		Title:         "developer",
		NameForStripe: "Developer Monthly",
		Amount:        2450,
		Interval:      stripe.Month,
	},
	"developer_year": &Plan{
		Title:         "developer",
		NameForStripe: "Developer Yearly",
		Amount:        23940,
		Interval:      stripe.Year,
	},
	"professional_month": &Plan{
		Title:         "professional",
		NameForStripe: "Professional Monthly",
		Amount:        4950,
		Interval:      stripe.Month,
	},
	"professional_year": &Plan{
		Title:         "professional",
		NameForStripe: "Professional Yearly",
		Amount:        47940,
		Interval:      stripe.Year,
	},
	"super_month": &Plan{
		Title:         "super",
		NameForStripe: "Super Monthly",
		Amount:        9950,
		Interval:      stripe.Month,
	},
	"super_year": &Plan{
		Title:         "super",
		NameForStripe: "Super Yearly",
		Amount:        89400,
		Interval:      stripe.Year,
	},
}
