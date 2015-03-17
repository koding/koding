package paymentplan

import "fmt"

type Plan struct {
	Title, NameForStripe string
	Amount               uint64
	Interval             PlanInterval
	Value                int
}

type PlanInterval struct {
	Name string
}

var (
	Year  = PlanInterval{"year"}
	Month = PlanInterval{"month"}
)

func (p *PlanInterval) ToString() string {
	return p.Name
}

func GetPlanValue(title, interval string) int {
	key := fmt.Sprintf("%s_%s", title, interval)
	value, ok := DefaultPlans[key]
	if !ok {
		return 0
	}

	return value.Value
}

// Predefined list of plans. There are currently 5 tiers:
// "free", "hobbyist", "developer", "professional" "super"
// and 2 intervals: "month" and "year".
var DefaultPlans = map[string]*Plan{
	"free_month": &Plan{
		Title:         "free",
		NameForStripe: "Free",
		Amount:        0,
		Interval:      Month,
		Value:         1,
	},
	"free_year": &Plan{
		Title:         "free",
		NameForStripe: "Free",
		Amount:        0,
		Interval:      Year,
		Value:         1,
	},
	"hobbyist_month": &Plan{
		Title:         "hobbyist",
		NameForStripe: "Hobbyist Monthy",
		Amount:        1250,
		Interval:      Month,
		Value:         2,
	},
	"hobbyist_year": &Plan{
		Title:         "hobbyist",
		NameForStripe: "Hobbyist Yearly",
		Amount:        11940,
		Interval:      Year,
		Value:         2,
	},
	"developer_month": &Plan{
		Title:         "developer",
		NameForStripe: "Developer Monthly",
		Amount:        2450,
		Interval:      Month,
		Value:         3,
	},
	"developer_year": &Plan{
		Title:         "developer",
		NameForStripe: "Developer Yearly",
		Amount:        23940,
		Interval:      Year,
		Value:         3,
	},
	"professional_month": &Plan{
		Title:         "professional",
		NameForStripe: "Professional Monthly",
		Amount:        4950,
		Interval:      Month,
		Value:         4,
	},
	"professional_year": &Plan{
		Title:         "professional",
		NameForStripe: "Professional Yearly",
		Amount:        47940,
		Interval:      Year,
		Value:         4,
	},
	"super_month": &Plan{
		Title:         "super",
		NameForStripe: "Super Monthly",
		Amount:        9950,
		Interval:      Month,
		Value:         5,
	},
	"super_year": &Plan{
		Title:         "super",
		NameForStripe: "Super Yearly",
		Amount:        89400,
		Interval:      Year,
		Value:         5,
	},
	"koding": &Plan{
		Title:         "koding",
		NameForStripe: "Koding",
		Amount:        0,
		Interval:      Month,
	},
	"betatester": &Plan{
		Title:         "betatester",
		NameForStripe: "Betatester",
		Amount:        0,
		Interval:      Month,
	},
}
