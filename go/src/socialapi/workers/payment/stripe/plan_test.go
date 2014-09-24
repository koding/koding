package stripe

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"

	stripePlan "github.com/stripe/stripe-go/plan"
)

func TestCreateAndFindPlan(t *testing.T) {
	Convey("Given default plans object", t, func() {
		err := CreateDefaultPlans()
		So(err, ShouldBeNil)

		Convey("Then it should create the plans in Stripe", func() {
			for id, _ := range DefaultPlans {
				_, err := stripePlan.Get(id, nil)
				So(err, ShouldBeNil)
			}
		})

		Convey("Then it should save the plans", func() {
			for _, pl := range DefaultPlans {
				plan, err := FindPlanByTitleAndInterval(pl.Title, string(pl.Interval))

				So(err, ShouldBeNil)
				So(plan, ShouldNotBeNil)

				So(plan.Title, ShouldEqual, pl.Title)
			}
		})
	})
}
