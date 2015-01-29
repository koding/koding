package main

import (
	"encoding/json"
	"net/http"
)

type stripeActionType func([]byte, *Controller) error

var stripeActions = map[string]stripeActionType{
	"customer.subscription.created": stripeSubscriptionCreated,
	"customer.subscription.deleted": stripeSubscriptionDeleted,
	"invoice.created":               stripePaymentSucceeded,
	"charge.refunded":               stripePaymentRefunded,
	"charge.failed":                 stripePaymentFailed,
	"customer.deleted":              stripeCustomerDeleted,
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

type stripeMux struct {
	Controller *Controller
}

func (s *stripeMux) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var req *stripeWebhookRequest

	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		Log.Error("Error marshalling Stripe webhook '%v' : %v", s, err)

		w.WriteHeader(500)
		return
	}

	action, ok := stripeActions[req.Name]
	if !ok {
		Log.Debug("Stripe webhook: %s not implemented", req.Name)
		return
	}

	data, err := json.Marshal(req.Data.Object)
	if err != nil {
		Log.Error("Error marshalling Stripe webhook '%v' : %v", s, err)

		w.WriteHeader(500)
		return
	}

	err = action(data, s.Controller)
	if err != nil {
		Log.Error("Stripe webhook: %s action failed: %s", req.Name, err)

		w.WriteHeader(500)
		return
	}
}
