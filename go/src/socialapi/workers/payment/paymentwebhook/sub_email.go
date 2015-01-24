package main

import (
	"koding/kodingemail"
	"socialapi/workers/payment/paymentemail"
)

func subscriptionEmail(customerProviderId, planName string, action paymentemail.Action, email *kodingemail.SG) error {
	emailAddress, err := getEmailForCustomer(customerProviderId)
	if err != nil {
		return err
	}

	opts := map[string]string{"planName": planName}

	return paymentemail.Send(email, action, emailAddress, opts)
}
