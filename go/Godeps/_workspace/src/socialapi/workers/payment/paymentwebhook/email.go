package main

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/email/emailsender"
)

type Action int

const (
	SubscriptionCreated Action = iota
	SubscriptionChanged
	SubscriptionDeleted
	PaymentCreated
	PaymentRefunded
	PaymentFailed
)

var EmailSubjects = map[Action]string{
	SubscriptionCreated: "bought a subscription",
	SubscriptionDeleted: "canceled their subscription",
	SubscriptionChanged: "changed their subscription",
	PaymentCreated:      "received an invoice",
	PaymentRefunded:     "received a refuned",
	PaymentFailed:       "failed to pay",
}

var ErrEmailActionNotFound = errors.New("action not found")

func SendEmail(customerId string, action Action, opts map[string]interface{}) error {
	subject, ok := EmailSubjects[action]
	if !ok {
		return ErrEmailActionNotFound
	}

	user, err := getUserForCustomer(customerId)
	if err != nil {
		return err
	}

	account, err := modelhelper.GetAccount(user.Name)
	if err != nil {
		return err
	}

	opts["firstName"] = account.Profile.FirstName

	mail := &emailsender.Mail{
		To:         user.Email,
		Subject:    subject,
		Properties: &emailsender.Properties{Username: user.Name, Options: opts},
	}

	return emailsender.Send(mail)
}
