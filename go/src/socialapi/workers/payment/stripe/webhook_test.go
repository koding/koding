package stripe

import (
	"fmt"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func rawSubscriptionDeletedData(id string) []byte {
	raw := `{"id": "%s"}`
	data := fmt.Sprintf(raw, id)

	return []byte(data)
}

func TestSubscriptionDeletedWebhook(t *testing.T) {
	Convey("Given customer has an unpaid subscription", t,
		subscribeWithReturnsFn(func(customer *paymentmodels.Customer, subscription *paymentmodels.Subscription) {
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

var (
	periodStart int64 = 1445023445
	periodEnd   int64 = 1476645845
)

func rawInvoiceCreatedData(subscriptionId string) ([]byte, string) {
	planProviderId := LowerPlanProviderId

	raw := `{
		"id": "in_00000000000000",
		"lines": {
			"data": [
				{
					"id": "%s",
					"plan": { "id": "%s" },
					"period": {
						"start": %d,
						"end": %d
					}
				}
			],
			"count": 1
		}
	}`

	data := fmt.Sprintf(
		raw, subscriptionId, planProviderId, periodStart, periodEnd,
	)

	return []byte(data), planProviderId
}

func TestInvoiceCreatedWebhook(t *testing.T) {
	Convey("Given customer has a subscription", t,
		subscribeWithReturnsFn(func(customer *paymentmodels.Customer, subscription *paymentmodels.Subscription) {
			subscriptionProviderId := subscription.ProviderSubscriptionId
			data, planProviderId := rawInvoiceCreatedData(subscriptionProviderId)

			err := InvoiceCreatedWebhook(data)
			So(err, ShouldBeNil)

			Convey("When 'invoice.created' webhook is fired", func() {
				Convey("Then subscription plan, period start, end are updated", func() {
					err := subscription.ById(subscription.Id)
					So(err, ShouldBeNil)

					plan := paymentmodels.NewPlan()
					err = plan.ByProviderId(planProviderId, ProviderName)
					So(err, ShouldBeNil)

					So(subscription.PlanId, ShouldEqual, plan.Id)
					So(subscription.CurrentPeriodStart, ShouldHappenOnOrBefore, time.Unix(periodStart, 0).UTC())
					So(subscription.CurrentPeriodEnd, ShouldHappenOnOrBefore, time.Unix(periodEnd, 0).UTC())
					So(subscription.CanceledAt.IsZero(), ShouldBeTrue)
				})
			})
		}),
	)
}
