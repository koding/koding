package stripe

import (
	"encoding/json"
	"socialapi/workers/payment/paymentmodels"
	"time"
)

//----------------------------------------------------------
// SubscriptionDeleted
//----------------------------------------------------------

type SubscriptionDeletedWebhookRequest struct {
	ID string `json:"id"`
}

func SubscriptionDeletedWebhook(raw []byte) error {
	var req *SubscriptionDeletedWebhookRequest

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	subscription := paymentmodels.NewSubscription()
	err = subscription.ByProviderId(req.ID, ProviderName)
	if err != nil {
		return err
	}

	if subscription.State == paymentmodels.SubscriptionStateActive {
		err = subscription.UpdateState(paymentmodels.SubscriptionStateExpired)
	}

	return err
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

func InvoiceCreatedWebhook(raw []byte) error {
	var req *InvoiceCreatedWebhookRequest

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	if !IsLineCountAllowed(req.Lines.Count) {
		Log.Error("'invoice.created': Line count: %s not allowed", req.Lines.Count)
		return nil
	}

	item := req.Lines.Data[0]

	subscription := paymentmodels.NewSubscription()
	err = subscription.ByProviderId(item.SubscriptionId, ProviderName)
	if err != nil {
		return err
	}

	plan := paymentmodels.NewPlan()
	plan.ByProviderId(item.Plan.PlanId, ProviderName)
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

type CustomerDeletedWebhookRequest struct {
	ID string `json:"id"`
}

func CustomerDeletedWebhook(raw []byte) error {
	var req *CustomerDeletedWebhookRequest

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return err
	}

	customer := paymentmodels.NewCustomer()
	err = customer.ByProviderCustomerId(req.ID)
	if err != nil {
		return err
	}

	return customer.DeleteSubscriptionsAndItself()
}
