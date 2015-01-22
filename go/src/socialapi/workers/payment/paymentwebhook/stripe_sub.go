package main

import (
	"encoding/json"
	"socialapi/workers/payment/paymentemail"
	"socialapi/workers/payment/stripe"
)

func sendSubscriptionCreatedEmail(raw []byte) error {
	email, opts, err := _subWebhook(raw)
	if err != nil {
		return err
	}

	return paymentemail.Send(paymentemail.SubscriptionCreated, email, opts)
}

func sendSubscriptionDeletedEmail(raw []byte) error {
	email, opts, err := _subWebhook(raw)
	if err != nil {
		return err
	}

	return paymentemail.Send(paymentemail.SubscriptionDeleted, email, opts)
}

func _subWebhook(raw []byte) (string, *paymentemail.Options, error) {
	// subscription created, deleted sends 'subscription' type in webhook
	// can make this more generic
	var req *stripe.SubscriptionDeletedWebhookRequest

	err := json.Unmarshal(raw, &req)
	if err != nil {
		return "", nil, err
	}

	email, err := getEmailForCustomer(req.CustomerId)
	if err != nil {
		return "", nil, err
	}

	opts := &paymentemail.Options{
		PlanName: req.Plan.Name,
	}

	return email, opts, nil
}

// TODO: move to stripe package
type stripeCard struct {
	Id      string `json:"id"`
	ExpYear string `json:"exp_year"`
	Last4   string `json:"last4"`
	Brand   string `json:"brand"`
}

type stripeChargeRefundWebhookReq struct {
	Card       *stripeCard `json:"card"`
	Currency   string      `json:"currency"`
	Amount     float64     `json:"amount"`
	CustomerId string      `json:"customer"`
}
