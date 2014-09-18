package stripe

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"

	"github.com/stripe/stripe-go"
	stripeSub "github.com/stripe/stripe-go/sub"
)

func TestCreateAndFindSubscription(t *testing.T) {
	Convey("Given plan and customer id", t, func() {
		plan, err := FindPlanByTitleAndInterval(StartingPlan, StartingInterval)

		So(err, ShouldBeNil)
		So(plan, ShouldNotBeNil)
		So(plan.ProviderPlanId, ShouldNotEqual, "")

		token, accId, email := generateFakeUserInfo()
		customer, err := CreateCustomer(token, accId, email)

		So(err, ShouldBeNil)
		So(customer, ShouldNotBeNil)

		sub, err := CreateSubscription(customer, plan)
		So(err, ShouldBeNil)

		subParams := &stripe.SubParams{
			Customer: customer.ProviderCustomerId,
			Plan:     plan.ProviderPlanId,
		}

		stripeSubscriptionId := sub.ProviderSubscriptionId

		s, err := stripeSub.Get(stripeSubscriptionId, subParams)

		Convey("Then it should create subscription in Stripe", func() {
			So(err, ShouldBeNil)
			So(s.Id, ShouldEqual, stripeSubscriptionId)
		})

		Convey("Then it should save subscription", func() {
			subs, err := FindCustomerActiveSubscriptions(customer)

			So(err, ShouldBeNil)
			So(len(subs), ShouldEqual, 1)

			sub := subs[0]
			So(sub.ProviderSubscriptionId, ShouldEqual, stripeSubscriptionId)
		})
	})
}
