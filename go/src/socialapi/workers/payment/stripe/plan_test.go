package stripe

import (
	"socialapi/workers/payment/paymentplan"
	"testing"

	. "github.com/smartystreets/goconvey/convey"

	stripePlan "github.com/stripe/stripe-go/plan"
)

func TestCreateAndFindPlan(t *testing.T) {
	Convey("Given default plans object", t, func() {
		err := CreateDefaultPlans()
		So(err, ShouldBeNil)

		Convey("Then it should create the plans in Stripe", func() {
			for id, _ := range paymentplan.DefaultPlans {
				_, err := stripePlan.Get(id, nil)
				So(err, ShouldBeNil)
			}
		})

		Convey("Then it should save the plans", func() {
			for _, pl := range paymentplan.DefaultPlans {
				plan, err := FindPlan(pl.Title, pl.Interval.ToString(), pl.TypeConstant)
				So(err, ShouldBeNil)
				So(plan, ShouldNotBeNil)

				So(plan.Title, ShouldEqual, pl.Title)
			}
		})
	})
}
