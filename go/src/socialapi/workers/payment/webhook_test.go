package payment

import (
	"fmt"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"testing"

	"github.com/koding/logging"
	. "github.com/smartystreets/goconvey/convey"
)

func init() {
	Log.SetLevel(logging.CRITICAL)
}

func rawSubscriptionDeletedData(id string) []byte {
	raw := `{"id": "%s"}`
	data := fmt.Sprintf(raw, id)

	return []byte(data)
}

func TestSubscriptionDeletedWebhook(t *testing.T) {
	// Convey("Given customer has an unpaid subscription", t,
	// 	subscribeWithReturnsFn(func(customer *paymentmodels.Customer, subscription *paymentmodels.Subscription) {
	// 		subscriptionProviderId := subscription.ProviderSubscriptionId

	// 		req := &webhookmodels.StripeSubscription{ID: subscriptionProviderId}
	// 		err := SubscriptionDeletedWebhook(req)

	// 		Convey("When webhook is fired after third failed invoice", func() {
	// 			Convey("Then customer subscription is marked as expired", func() {
	// 				So(err, ShouldBeNil)
	// 			})

	// 			Convey("Then customer has no active subscription", func() {
	// 				_, err := customer.FindActiveSubscription()

	// 				shouldGetErr := paymenterrors.ErrCustomerNotSubscribedToAnyPlans
	// 				So(err, ShouldEqual, shouldGetErr)
	// 			})

	// 			Convey("Then customer's has no credit card", func() {
	// 				card, err := GetCreditCard(customer.OldId)
	// 				So(err, ShouldBeNil)
	// 				So(card.LastFour, ShouldBeEmpty)
	// 			})
	// 		})
	// 	}),
	// )
}

var (
	periodStart int64 = 1445023445
	periodEnd   int64 = 1476645845
)

func rawInvoiceCreatedData(subscriptionId string) (*webhookmodels.StripeInvoice, string) {
	return nil, "nil"
	// planProviderId := LowerPlanProviderId

	// invoiceLine := webhookmodels.StripeInvoiceData{
	// 	SubscriptionId: subscriptionId,
	// 	Plan: webhookmodels.StripePlan{
	// 		ID: planProviderId,
	// 	},
	// 	Period: webhookmodels.StripePeriod{
	// 		Start: float64(periodStart),
	// 		End:   float64(periodEnd),
	// 	},
	// }

	// invoice := &webhookmodels.StripeInvoice{
	// 	ID: "in_00000000000000",
	// 	Lines: webhookmodels.StripeInvoiceLines{
	// 		Data:  []webhookmodels.StripeInvoiceData{invoiceLine},
	// 		Count: 1,
	// 	},
	// }

	// return invoice, planProviderId
}

func rawInvoiceCreatedDataPlanChange(subscriptionId string) (*webhookmodels.StripeInvoice, string) {
	invoice, planProviderId := rawInvoiceCreatedData(subscriptionId)

	oldId := invoice.Lines.Data[0].SubscriptionId
	invoice.Lines.Data[0].Id = oldId
	invoice.Lines.Data[0].SubscriptionId = ""

	return invoice, planProviderId
}

func TestInvoiceCreatedWebhook(t *testing.T) {
	Convey("Given customer has a subscription", t, nil) // subscribeWithReturnsFn(func(customer *paymentmodels.Customer, subscription *paymentmodels.Subscription) {
	// 	subscriptionProviderId := subscription.ProviderSubscriptionId
	// 	invoice, planProviderId := rawInvoiceCreatedData(subscriptionProviderId)

	// 	err := InvoiceCreatedWebhook(invoice)
	// 	So(err, ShouldBeNil)

	// 	Convey("When 'invoice.created' webhook is fired", func() {
	// 		Convey("Then period start, end are updated", func() {
	// 			err := subscription.ById(subscription.Id)
	// 			So(err, ShouldBeNil)

	// 			plan := paymentmodels.NewPlan()
	// 			err = plan.ByProviderId(planProviderId, ProviderName)
	// 			So(err, ShouldBeNil)

	// 			So(subscription.CurrentPeriodStart, ShouldHappenOnOrBefore, time.Unix(periodStart, 0).UTC())
	// 			So(subscription.CurrentPeriodEnd, ShouldHappenOnOrBefore, time.Unix(periodEnd, 0).UTC())
	// 			So(subscription.CanceledAt.IsZero(), ShouldBeTrue)
	// 		})
	// 	})
	// }),

	Convey("Given customer has a subscription", t, nil) // subscribeWithReturnsFn(func(customer *paymentmodels.Customer, subscription *paymentmodels.Subscription) {
	// 	subscriptionProviderId := subscription.ProviderSubscriptionId
	// 	invoice, planProviderId := rawInvoiceCreatedDataPlanChange(subscriptionProviderId)

	// 	err := InvoiceCreatedWebhook(invoice)
	// 	So(err, ShouldBeNil)

	// 	Convey("When 'invoice.created' webhook is fired", func() {
	// 		Convey("Then period start, end are updated", func() {
	// 			err := subscription.ById(subscription.Id)
	// 			So(err, ShouldBeNil)

	// 			plan := paymentmodels.NewPlan()
	// 			err = plan.ByProviderId(planProviderId, ProviderName)
	// 			So(err, ShouldBeNil)

	// 			So(subscription.CurrentPeriodStart, ShouldHappenOnOrBefore, time.Unix(periodStart, 0).UTC())
	// 			So(subscription.CurrentPeriodEnd, ShouldHappenOnOrBefore, time.Unix(periodEnd, 0).UTC())
	// 			So(subscription.CanceledAt.IsZero(), ShouldBeTrue)
	// 		})
	// 	})
	// }),

}
