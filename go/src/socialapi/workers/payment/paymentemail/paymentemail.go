package paymentemail

import (
	"fmt"
	"koding/db/models"
	"socialapi/workers/email/emailsender"
)

var SendgridTemplates = map[Action]string{
	SubscriptionCreated: "SubscriptionCreated",
	SubscriptionDeleted: "SubscriptionDeleted",
	SubscriptionChanged: "SubscriptionChanged",
	PaymentCreated:      "PaymentCreated",
	PaymentRefunded:     "PaymentRefunded",
	PaymentFailed:       "PaymentFailed",
}

func Send(user *models.User, action Action, substituions map[string]string) error {
	actionName, ok := SendgridTemplates[action]
	if !ok {
		return fmt.Errorf("%s has no template", action)
	}

	mail := &emailsender.Mail{
		To:      user.Email,
		Subject: actionName,
		Properties: &emailsender.Properties{
			Username:     user.Name,
			Substituions: substituions,
		},
	}

	return emailsender.Send(mail)
}
