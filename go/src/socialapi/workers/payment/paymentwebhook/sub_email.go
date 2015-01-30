package main

import (
	"socialapi/workers/payment/paymentemail"

	"github.com/koding/kodingemail"
)

func subscriptionEmail(customerId, planName string, action paymentemail.Action, email kodingemail.Client) error {
	emailAddress, err := getEmailForCustomer(customerId)
	if err != nil {
		return err
	}

	opts := map[string]string{"planName": planName}

	return paymentemail.Send(email, action, emailAddress, opts)
}
