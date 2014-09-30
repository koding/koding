package stripe

import (
	"socialapi/workers/payment/paymentmodels"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	"github.com/stripe/stripe-go"
	stripeSub "github.com/stripe/stripe-go/sub"
)

func TestCustomer1(t *testing.T) {
	Convey("Given a description (id) and email", t,
		createCustomerFn(func(accId string, c *paymentmodel.Customer) {
			Convey("Then it should create an customer in Stripe", func() {
				stripeCustomerId := c.ProviderCustomerId
				So(checkCustomerExistsInStripe(stripeCustomerId), ShouldBeTrue)
			})

			Convey("Then it should save customer", func() {
				So(checkCustomerIsSaved(accId), ShouldBeTrue)
			})
		}),
	)
}

func TestCustomer2(t *testing.T) {
	Convey("Given an existing customer", t,
		subscribeFn(func(token, accId, email string) {
			customer, err := FindCustomerByOldId(accId)
			So(err, ShouldBeNil)

			err = DeleteCustomer(accId)
			So(err, ShouldBeNil)

			subscriptions, err := FindCustomerSubscriptions(customer)
			So(err, ShouldBeNil)

			sub := subscriptions[0]

			Convey("Then it should unsubscribe user", func() {
				So(sub.State, ShouldEqual, SubscriptionStateCanceled)
			})

			Convey("Then it should delete customer in Stripe", func() {
				subParams := &stripe.SubParams{
					Customer: customer.ProviderCustomerId,
				}

				_, err := stripeSub.Get(sub.ProviderSubscriptionId, subParams)
				So(err, ShouldNotBeNil)
			})
		}),
	)
}
