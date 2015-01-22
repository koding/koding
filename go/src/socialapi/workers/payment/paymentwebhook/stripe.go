package main

import (
	"encoding/json"
	"net/http"
	"socialapi/workers/payment/stripe"

	"github.com/coreos/go-log/log"
)

type stripeActionType func([]byte) error

var stripeActions = map[string][]stripeActionType{
	"customer.subscription.created": []stripeActionType{
		sendSubscriptionCreatedEmail,
	},

	"customer.subscription.deleted": []stripeActionType{
		stripe.SubscriptionDeletedWebhook,
		sendSubscriptionDeletedEmail,
	},

	"invoice.created":  []stripeActionType{stripe.InvoiceCreatedWebhook},
	"customer.deleted": []stripeActionType{stripe.CustomerDeletedWebhook},
	"charge.refunded":  []stripeActionType{sendChargeRefundedEmail},
	"charge.failed":    []stripeActionType{sendChargeFailedEmail},
}

type stripeWebhookRequest struct {
	Name     string `json:"type"`
	Created  int    `json:"created"`
	Livemode bool   `json:"livemode"`
	Id       string `json:"id"`
	Data     struct {
		Object interface{} `json:"object"`
	} `json:"data"`
}

type stripeMux struct{}

func (s *stripeMux) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var req stripeWebhookRequest

	err := json.NewDecoder(r.Body).Decode(req)
	if err != nil {
		log.Error("Error marshalling Stripe webhook '%v' : %v", s, err)
		return
	}

	actions, ok := stripeActions[req.Name]
	if !ok {
		log.Error("Stripe webhook: %s not implemented", req.Name)
		return
	}

	data, err := json.Marshal(req.Data.Object)
	if err != nil {
		log.Error("Error marshalling Stripe webhook '%v' : %v", s, err)
		return
	}

	for _, action := range actions {
		err := action(data)
		if err != nil {
			log.Error("Stripe webhook: %s action failed: %s", req.Name, err)
		}
	}

	// return 200 to webhook
}
