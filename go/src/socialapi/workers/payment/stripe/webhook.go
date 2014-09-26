package stripe

import (
	"encoding/json"
	"socialapi/workers/payment/paymentmodels"
)

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
