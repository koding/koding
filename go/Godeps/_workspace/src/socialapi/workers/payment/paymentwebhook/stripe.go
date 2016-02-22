package main

import (
	"encoding/json"
	"net/http"
)

type stripeActionType func([]byte, *Controller) error

var stripeActions = map[string]stripeActionType{
	"customer.subscription.created": stripeSubscriptionCreated,
	"customer.subscription.deleted": stripeSubscriptionDeleted,
	"customer.subscription.updated": stripeSubscriptionUpdated,
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
		Object json.RawMessage `json:"object"`
	} `json:"data"`
}

type stripeMux struct {
	Controller *Controller
}

func (s *stripeMux) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()
	var req *stripeWebhookRequest

	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		Log.Error("Stripe: error decoding webhook '%v' : %v", s, err)

		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	action, ok := stripeActions[req.Name]
	if !ok {
		Log.Debug("Stripe: webhook: %s not implemented", req.Name)
		return
	}

	err = action(req.Data.Object, s.Controller)
	if err != nil {
		Log.Debug("Stripe: webhook: %s action failed: %s", req.Name, err)

		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	Log.Debug("Stripe: succesfully processed webhook: %s", req.Name)
}
