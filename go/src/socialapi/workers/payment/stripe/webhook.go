package stripe

import (
	"encoding/json"
	"socialapi/workers/payment/paymentmodels"
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

	err = updateSubscriptionState(req.ID, SubscriptionStateExpired)
	if err != nil {
		return err
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
			Plan           struct {
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
		return nil
	}

	item := req.Lines.Data[0]

	subscription := paymentmodel.NewSubscription()
	err = subscription.ByProviderId(item.SubscriptionId, ProviderName)
	if err != nil {
		return err
	}

	plan := paymentmodel.NewPlan()
	plan.ByProviderId(item.Plan.PlanId, ProviderName)
	if err != nil {
		return err
	}

	if subscription.PlanId != plan.Id {
		err = subscription.UpdatePlan(plan.Id, plan.AmountInCents)
		if err != nil {
			return err
		}
	}

	return nil
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

func updateSubscriptionState(providerId, state string) error {
	subscription := paymentmodel.NewSubscription()
	err := subscription.ByProviderId(providerId, ProviderName)
	if err != nil {
		return err
	}

	err = subscription.UpdateState(state)
	if err != nil {
		return err
	}

	return nil
}
