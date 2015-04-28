package main

import (
	"encoding/json"
	"fmt"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"socialapi/workers/payment/stripe"
)

func stripeSubscriptionCreated(raw []byte, c *Controller) error {
	sub, err := unmarshalSubscription(raw)
	if err != nil {
		return err
	}

	return subscriptionEmail(sub.CustomerId, sub.Plan.Name, SubscriptionCreated)
}

func stripeSubscriptionDeleted(raw []byte, c *Controller) error {
	sub, err := unmarshalSubscription(raw)
	if err != nil {
		return err
	}

	err = stopMachinesForUser(sub.CustomerId, c.Kite)
	if err != nil {
		Log.Error(fmt.Sprintf("Error stopping machines for customer:%s, %s",
			sub.CustomerId, err,
		))
	}

	err = stripe.SubscriptionDeletedWebhook(sub)
	if err != nil && err != bongo.RecordNotFound {
		Log.Error(fmt.Sprintf(
			"Error processing 'SubscriptionDeleted' webhook for customer:%s, %s",
			sub.CustomerId, err,
		))
	}

	return subscriptionEmail(sub.CustomerId, sub.Plan.Name, SubscriptionDeleted)
}

func stripeSubscriptionUpdated(raw []byte, c *Controller) error {
	sub, err := unmarshalSubscription(raw)
	if err != nil {
		return err
	}

	previousPlan := sub.PreviousAttributes.Plan
	currentPlanName := sub.Plan.Name

	if isSamePlan(previousPlan.Name, currentPlanName) {
		return nil
	}

	return subscriptionEmail(sub.CustomerId, currentPlanName, SubscriptionChanged)
}

func unmarshalSubscription(raw []byte) (*webhookmodels.StripeSubscription, error) {
	var req *webhookmodels.StripeSubscription

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return nil, err
	}

	return req, nil
}

func isSamePlan(previousPlanName, newPlanName string) bool {
	return previousPlanName == "" || previousPlanName == newPlanName
}
