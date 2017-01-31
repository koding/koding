package payment

import (
	"socialapi/config"
	"socialapi/workers/common/tests"
	"testing"

	. "github.com/smartystreets/goconvey/convey"

	"github.com/stripe/stripe-go"
	stripePlan "github.com/stripe/stripe-go/plan"
)

func TestCreateDefaultPlans(t *testing.T) {
	tests.WithConfiguration(t, func(c *config.Config) {
		stripe.Key = c.Stripe.SecretToken

		Convey("Given default plans object", t, func() {
			So(CreateDefaultPlans(), ShouldBeNil)

			Convey("Plans should be in Stripe", func() {
				for _, plan := range plans {
					_, err := stripePlan.Get(plan.ID, nil)
					So(err, ShouldBeNil)
				}
			})

			Convey("Trying to create them again should not return error", func() {
				So(CreateDefaultPlans(), ShouldBeNil)
			})
		})
	})
}
