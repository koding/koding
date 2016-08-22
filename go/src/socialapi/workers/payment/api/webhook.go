package api

import (
	"net/http"
	"net/url"

	stripe "github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/event"

	"socialapi/workers/common/response"
	"socialapi/workers/payment"
)

// Webhook handles events from stripe
func Webhook(u *url.URL, h http.Header, req *stripe.Event) (int, http.Header, interface{}, error) {
	// if we dont support the handler, just return success so they dont try again.
	handler, err := payment.GetHandler(req.Type)
	if err != nil {
		return response.NewDefaultOK()
	}

	// get the event from stripe api again since they dont provide a way to
	// authenticate incoming requests
	event, err := event.Get(req.ID, nil)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := handler(event.Data.Raw); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewDefaultOK()
}
