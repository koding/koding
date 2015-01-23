package paymentemail

import "koding/kodingemail"

type ActionFuncType func(string) error

var Actions = map[Action][]ActionFuncType{
	SubscriptionCreated: []ActionFuncType{},
}

type Options struct {
	PlanName  string
	Currency  string
	CardBrand string
	CardLast4 string

	AmountRefunded float64
	AmountDue      float64
}

func Send(client *kodingemail.SG, actionName Action, email string, opts *Options) error {
	return nil
}
