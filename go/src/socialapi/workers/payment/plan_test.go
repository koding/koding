package payment

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"

	stripePlan "github.com/stripe/stripe-go/plan"
)

func TestCreateDefaultPlans(t *testing.T) {
	withConfiguration(t, func() {
		Convey("Given default plans object", t, func() {
			err := CreateDefaultPlans()
			So(err, ShouldBeNil)

			Convey("Plans should be in Stripe", func() {
				for _, plan := range Plans {
					_, err := stripePlan.Get(plan.ID, nil)
					So(err, ShouldBeNil)
				}
			})

			Convey("Trying to create them again should not return error", func() {
				err := CreateDefaultPlans()
				So(err, ShouldBeNil)
			})
		})
	})
}
