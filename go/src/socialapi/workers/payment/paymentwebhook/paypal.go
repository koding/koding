package main

import (
	"encoding/json"
	"koding/kodingemail"
	"net/http"
	"socialapi/workers/payment/paypal"

	"github.com/coreos/go-log/log"
)

type paypalActionType func(string) error

var paypalActionExpire = []paypalActionType{
	paypal.ExpireSubscription,
}

var paypalActions = map[string][]paypalActionType{
	"Denied":   paypalActionExpire,
	"Expired":  paypalActionExpire,
	"Failed":   paypalActionExpire,
	"Reversed": paypalActionExpire,
	"Voided":   paypalActionExpire,
	"recurring_payment_profile_cancel": paypalActionExpire,
}

type paypalWebhookRequest struct {
	TransactionType string `json:"txn_type"`
	Status          string `json:"payment_status"`
	PayerId         string `json:"payer_id"`
}

type paypalMux struct {
	EmailClient *kodingemail.SG
}

func (p *paypalMux) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var req paypalWebhookRequest

	err := json.NewDecoder(r.Body).Decode(req)
	if err != nil {
		log.Error("Error marshalling Paypal webhook '%v' : %v", p, err)
		return
	}

	actions, ok := paypalActions[req.Status]
	if !ok {
		actions, ok = paypalActions[req.TransactionType]
		if !ok {
			return
		}
	}

	for _, action := range actions {
		err := action(req.PayerId)
		if err != nil {
			log.Error("Paypal webhook: %s action failed: %s", req.PayerId, err)
		}
	}
}
