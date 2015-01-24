package stripe

import (
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"time"
)

//----------------------------------------------------------
// SubscriptionDeleted
//----------------------------------------------------------

func SubscriptionDeletedWebhook(req *webhookmodels.StripeSubscription) error {
	subscription := paymentmodels.NewSubscription()
	err := subscription.ByProviderId(req.ID, ProviderName)
	if err != nil {
		return err
	}

	if subscription.State == paymentmodels.SubscriptionStateActive {
		return subscription.Expire()
	}

	return nil
}

//----------------------------------------------------------
// InvoiceCreated
//----------------------------------------------------------

type InvoiceCreatedWebhookRequest struct {
	Id    string `json:"id"`
	Lines struct {
		Data []struct {
			SubscriptionId string `json:"id"`
			Period         struct {
				Start float64 `json:"start"`
				End   float64 `json:"end"`
			} `json:"period"`
			Plan struct {
				PlanId string `json:"id"`
			} `json:"plan"`
		} `json:"data"`
		Count int `json:"count"`
	} `json:"lines"`
}

func InvoiceCreatedWebhook(req *webhookmodels.StripeInvoice) error {
	if !IsLineCountAllowed(req.Lines.Count) {
		Log.Error("'invoice.created': Line count: %d not allowed", req.Lines.Count)
		return nil
	}

	item := req.Lines.Data[0]

	subscription := paymentmodels.NewSubscription()
	err := subscription.ByProviderId(item.SubscriptionId, ProviderName)
	if err != nil {
		return err
	}

	plan := paymentmodels.NewPlan()
	plan.ByProviderId(item.Plan.ID, ProviderName)
	if err != nil {
		return err
	}

	if subscription.PlanId != plan.Id {
		Log.Info(
			"'invoice.created': subscription: %v has planId: %v, but 'invoiced.created' webhook has planId: %v.",
			subscription.Id, subscription.PlanId, plan.Id,
		)
	}

	Log.Info(
		"'invoice.created': Updating subscription: %v to planId: %v, starting: %v",
		subscription.Id, plan.Id, time.Unix(int64(item.Period.Start), 0),
	)

	err = subscription.UpdateInvoiceCreated(
		plan.AmountInCents, plan.Id,
		int64(item.Period.Start), int64(item.Period.End),
	)

	return err
}

//----------------------------------------------------------
// CustomerDeleted
//----------------------------------------------------------

func CustomerDeletedWebhook(req *webhookmodels.StripeCustomer) error {
	customer := paymentmodels.NewCustomer()
	err := customer.ByProviderCustomerId(req.ID)
	if err != nil {
		return err
	}

	return customer.DeleteSubscriptionsAndItself()
}
