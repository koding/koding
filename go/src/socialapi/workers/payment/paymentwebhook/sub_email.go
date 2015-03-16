package main

import (
	"socialapi/workers/payment/paymentemail"

	"github.com/koding/kodingemail"
)

func subscriptionEmail(customerId, planName string, action paymentemail.Action, email kodingemail.Client) error {
	user, err := getUserForCustomer(customerId)
	if err != nil {
		return err
	}

	opts := map[string]string{"planName": planName}

	Log.Info("Sent subscription email to: %s with plan: %s", user.Email,
		planName)

	return paymentemail.Send(user, action, opts)
}
