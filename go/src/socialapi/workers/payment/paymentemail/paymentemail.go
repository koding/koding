package paymentemail

import (
	"fmt"
	"koding/kodingemail"
)

var Templates = map[Action]string{
	SubscriptionCreated: "",
	ChargeRefunded:      "",
	ChargeFailed:        "",
	SubscriptionDeleted: "",
	InvoiceCreated:      "",
}

func Send(client *kodingemail.SG, actionName Action, to string, subs map[string]string) error {
	templateId, ok := Templates[actionName]
	if !ok {
		return fmt.Errorf("%s has no template", actionName)
	}

	return client.SendTemplateEmail(to, templateId, subs)
}
