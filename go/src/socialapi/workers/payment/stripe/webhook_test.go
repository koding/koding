package stripe

import (
	"fmt"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func rawSubscriptionDeletedData(id string) []byte {
	raw := `{
		"id": "%s",
		"plan": {
			"interval": "month",
			"name": "Free plan",
			"created": 1410394341,
			"amount": 0,
			"currency": "usd",
			"id": "1_00000000000000",
			"object": "plan",
			"livemode": false,
			"interval_count": 1,
			"trial_period_days": null,
			"metadata": {},
			"statement_description": "0 plan"
		},
		"object": "subscription",
		"start": 1411683076,
		"status": "canceled",
		"customer": "cus_00000000000000",
		"cancel_at_period_end": false,
		"current_period_start": 1411683076,
		"current_period_end": 1414275076,
		"ended_at": 1411681278,
		"trial_start": null,
		"trial_end": null,
		"canceled_at": null,
		"quantity": 1,
		"application_fee_percent": null,
		"discount": null,
		"metadata": {}
	}
`

	data := fmt.Sprintf(raw, id)

	return []byte(data)
}

func TestSubscriptionDeletedWebhook(t *testing.T) {
	Convey("Given customer has an unpaid subscription", t,
		subscribeWithReturnsFn(func(customer *paymentmodel.Customer, subscription *paymentmodel.Subscription) {
			subscriptionProviderId := subscription.ProviderSubscriptionId

			data := rawSubscriptionDeletedData(subscriptionProviderId)
			err := SubscriptionDeletedWebhook(data)

			Convey("When webhook is fired after third failed invoice", func() {
				Convey("Then customer subscription is marked as expired", func() {
					So(err, ShouldBeNil)
				})

				Convey("Then customer's active subscription is empty", func() {
					_, err := customer.FindActiveSubscription()

					shouldGetErr := paymenterrors.ErrCustomerNotSubscribedToAnyPlans
					So(err, ShouldEqual, shouldGetErr)
				})
			})
		}),
	)
}
