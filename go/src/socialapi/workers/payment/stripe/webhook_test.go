package stripe

import (
	"fmt"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
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

			req := &webhookmodels.StripeSubscription{ID: subscriptionProviderId}
			err := SubscriptionDeletedWebhook(req)

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

func rawInvoiceCreatedData(subscriptionId string) (*webhookmodels.StripeInvoice, string) {
	planProviderId := LowerPlanProviderId

	invoiceLine := webhookmodels.StripeInvoiceData{
		SubscriptionId: subscriptionId,
		Plan: webhookmodels.StripePlan{
			ID: planProviderId,
		},
		Period: webhookmodels.StripePeriod{
			Start: float64(periodStart),
			End:   float64(periodEnd),
		},
	}

	invoice := &webhookmodels.StripeInvoice{
		ID: "in_00000000000000",
		Lines: webhookmodels.StripeInvoiceLines{
			Data: []webhookmodels.StripeInvoiceData{invoiceLine},
		},
	}

	return invoice, planProviderId
}

func TestInvoiceCreatedWebhook(t *testing.T) {
	Convey("Given customer has a subscription", t,
		subscribeWithReturnsFn(func(customer *paymentmodels.Customer, subscription *paymentmodels.Subscription) {
			subscriptionProviderId := subscription.ProviderSubscriptionId
			invoice, planProviderId := rawInvoiceCreatedData(subscriptionProviderId)

			err := InvoiceCreatedWebhook(invoice)
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
