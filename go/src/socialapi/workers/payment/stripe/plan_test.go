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
			for title, _ := range DefaultPlans {
				_, err := stripePlan.Get(title, nil)
				So(err, ShouldBeNil)
			}
		})

		Convey("Then it should save the plans", func() {
			for title, _ := range DefaultPlans {
				plan, err := FindPlanByTitle(title)

				So(err, ShouldBeNil)
				So(plan, ShouldNotBeNil)

				So(plan.Title, ShouldEqual, title)
			}
		})
	})
}
