package main

import (
	"encoding/json"
	"fmt"
	"net/http"
)

type stripeActionType func([]byte) error

var stripeActions = map[string]stripeActionType{
	"customer.subscription.created": stripeSubscriptionCreated,
	"customer.subscription.deleted": stripeSubscriptionDeleted,
	"invoice.created":               stripeInvoiceCreated,
	"charge.refunded":               stripeChargeRefunded,
	"charge.failed":                 stripeChargeFailed,
	// "customer.deleted": []stripeActionType{stripe.CustomerDeletedWebhook},
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
	var req *stripeWebhookRequest

	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		fmt.Printf("Error marshalling Stripe webhook '%v' : %v", s, err)
		return
	}

	action, ok := stripeActions[req.Name]
	if !ok {
		fmt.Printf("Stripe webhook: %s not implemented", req.Name)
		return
	}

	data, err := json.Marshal(req.Data.Object)
	if err != nil {
		fmt.Printf("Error marshalling Stripe webhook '%v' : %v", s, err)
		return
	}

	err = action(data)
	if err != nil {
		fmt.Printf("Stripe webhook: %s action failed: %s", req.Name, err)
		return
	}
}
