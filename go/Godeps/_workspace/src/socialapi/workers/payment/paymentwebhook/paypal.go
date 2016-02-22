package main

import (
	"encoding/json"
	"net/http"
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
)

type paypalActionType func(*webhookmodels.PaypalGenericWebhook, *Controller) error

var paypalActions = map[string]paypalActionType{
	"recurring_payment_profile_created": paypalSubscriptionCreated,
	"recurring_payment_profile_cancel":  paypalSubscriptionDeleted,
	"recurring_payment":                 paypalPaymentSucceeded,
	"recurring_payment_suspended":       paypalPaymentFailed,

	"recurring_payment_suspended_due_to_max_failed_payment": paypalPaymentFailed,
}

type paypalMux struct {
	Controller *Controller
}

func (p *paypalMux) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var req *webhookmodels.PaypalGenericWebhook

	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		Log.Error("Paypal: error decoding webhook : %v", err)

		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	Log.Debug("Paypal: received webhook: %s", req.TransactionType)

	action, ok := paypalActions[req.TransactionType]
	if !ok {
		Log.Debug("Paypal: webhook: %s, %s not implemented", req.Status, req.TransactionType)
		return
	}

	err = action(req, p.Controller)
	if err != nil {
		Log.Error("Paypal: webhook: %s action: %s failed for user: %v", req.TransactionType, req.PayerId, err)

		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	Log.Debug("Paypal: succesfully processed webhook: %s for user: %s", req.TransactionType, req.PayerId)
}
