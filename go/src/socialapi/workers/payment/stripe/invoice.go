package stripe

import (
	"socialapi/workers/payment/paymentmodels"
	"time"

	stripe "github.com/stripe/stripe-go"
	stripeInvoice "github.com/stripe/stripe-go/invoice"
)

type StripeInvoiceResponse struct {
	Amount              int64     `json:"amount"`
	Paid                bool      `json:"paid"`
	PeriodStart         time.Time `json:"periodStart"`
	PeriodEnd           time.Time `json:"periodEnd"`
	*CreditCardResponse `json:"card"`
}

func FindInvoicesForCustomer(oldId string) ([]*StripeInvoiceResponse, error) {
	customer, err := paymentmodels.NewCustomer().ByOldId(oldId)
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

		if raw.Charge != nil && raw.Charge.Card != nil {
			invoice.CreditCardResponse = newCreditCardResponseFromStripe(raw.Charge.Card)
		}

		invoices = append(invoices, invoice)
	}

	return invoices, nil
}
