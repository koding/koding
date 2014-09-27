package stripe

import (
	"time"

	"github.com/stripe/stripe-go"
	stripeInvoice "github.com/stripe/stripe-go/invoice"
)

type StripeInvoiceResponse struct {
	Amount      int64     `json:"amount"`
	Paid        bool      `json:"paid"`
	PeriodStart time.Time `json"periodStart"`
	PeriodEnd   time.Time `json:"periodEnd"`
}

func FindInvoicesForCustomer(oldId string) ([]*StripeInvoiceResponse, error) {
	customer, err := FindCustomerByOldId(oldId)
	if err != nil {
		return nil, err
	}

	invoiceListParams := &stripe.InvoiceListParams{
		Customer: customer.ProviderCustomerId,
	}

	invoices := []*StripeInvoiceResponse{}

	list := stripeInvoice.List(invoiceListParams)
	for !list.Stop() {
		raw, err := list.Next()
		if err != nil {
			return nil, handleStripeError(err)
		}

		start := time.Unix(raw.Start, 0)
		end := time.Unix(raw.End, 0)

		invoice := &StripeInvoiceResponse{
			Amount:      raw.Amount,
			Paid:        raw.Paid,
			PeriodStart: start,
			PeriodEnd:   end,
		}

		invoices = append(invoices, invoice)
	}

	return invoices, nil
}
