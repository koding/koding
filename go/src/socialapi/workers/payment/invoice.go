package payment

import (
	"koding/db/mongodb/modelhelper"

	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/invoice"
)

// ListInvoicesForGroup lists invoices of a group
func ListInvoicesForGroup(groupName string, startingAfter string, limit int) ([]*stripe.Invoice, error) {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	if group.Payment.Customer.ID == "" {
		return nil, ErrCustomerNotExists
	}

	var invoices []*stripe.Invoice

	params := &stripe.InvoiceListParams{}
	params.Customer = group.Payment.Customer.ID
	params.Limit = limit
	params.Start = startingAfter
	i := invoice.List(params)
	for i.Next() {
		invoices = append(invoices, i.Invoice())
	}

	if err := i.Err(); err != nil {
		return nil, err
	}

	return invoices, nil
}
