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
	SubscriptionCreated: "SubscriptionCreated",
	SubscriptionDeleted: "SubscriptionDeleted",
	SubscriptionChanged: "SubscriptionChanged",
	PaymentCreated:      "PaymentCreated",
	PaymentRefunded:     "PaymentRefunded",
	PaymentFailed:       "PaymentFailed",
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
