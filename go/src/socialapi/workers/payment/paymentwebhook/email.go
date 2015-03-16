package main

import (
	"errors"
	"koding/db/models"
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

func Email(user *models.User, action Action, opts map[string]string) error {
	subject, ok := EmailSubjects[action]
	if !ok {
		return errors.New("")
	}

	mail := &emailsender.Mail{
		To:      user.Email,
		Subject: subject,
		Properties: &emailsender.Properties{
			Username:     user.Name,
			Substituions: opts,
		},
	}

	return emailsender.Send(mail)
}
