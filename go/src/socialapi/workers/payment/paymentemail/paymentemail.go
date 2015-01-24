package paymentemail

import (
	"fmt"
	"koding/kodingemail"
)

// these are template ids in sendgrid, these are hardcoded here
// since they don't change per environment and there's no point
// in putting them in the config
var SendgridTemplates = map[Action]string{
	SubscriptionCreated: "2db39090-2c27-4e8e-bb21-29b420644d9e",
	SubscriptionDeleted: "837c0118-8887-4c49-9c57-aa4ef49caf32",
	ChargeRefunded:      "436bd981-7cf6-4513-a3d3-45264b08e55c",
	ChargeFailed:        "d6710454-a9ec-4c01-843b-9c1df26664f0",
	InvoiceCreated:      "a12d3f77-d2a9-443e-92b0-5ed034ac9345",
}

func Send(client kodingemail.Client, action Action, to string, subs map[string]string) error {
	templateId, ok := SendgridTemplates[action]
	if !ok {
		return fmt.Errorf("%s has no template", action)
	}

	return client.SendTemplateEmail(to, templateId, subs)
}
