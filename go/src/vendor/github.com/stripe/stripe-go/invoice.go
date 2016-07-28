package stripe

import "encoding/json"

// InvoiceLineType is the list of allowed values for the invoice line's type.
// Allowed values are "invoiceitem", "subscription".
type InvoiceLineType string

const (
	TypeInvoiceItem  InvoiceLineType = "invoiceitem"
	TypeSubscription InvoiceLineType = "subscription"
)

// InvoiceParams is the set of parameters that can be used when creating or updating an invoice.
// For more details see https://stripe.com/docs/api#create_invoice, https://stripe.com/docs/api#update_invoice.
type InvoiceParams struct {
	Params
	Customer             string
	Desc, Statement, Sub string
	Fee                  uint64
	Closed, Forgive      bool
}

// InvoiceListParams is the set of parameters that can be used when listing invoices.
// For more details see https://stripe.com/docs/api#list_customer_invoices.
type InvoiceListParams struct {
	ListParams
	Date     int64
	Customer string
}

// InvoiceLineListParams is the set of parameters that can be used when listing invoice line items.
// For more details see https://stripe.com/docs/api#invoice_lines.
type InvoiceLineListParams struct {
	ListParams
	Id            string
	Customer, Sub string
}

// Invoice is the resource representing a Stripe invoice.
// For more details see https://stripe.com/docs/api#invoice_object.
type Invoice struct {
	Id           string            `json:"id"`
	Live         bool              `json:"livemode"`
	Amount       int64             `json:"amount_due"`
	Attempts     uint64            `json:"attempt_count"`
	Attempted    bool              `json:"attempted"`
	Closed       bool              `json:"closed"`
	Currency     Currency          `json:"currency"`
	Customer     *Customer         `json:"customer"`
	Date         int64             `json:"date"`
	Forgive      bool              `json:"forgiven"`
	Lines        *InvoiceLineList  `json:"lines"`
	Paid         bool              `json:"paid"`
	End          int64             `json:"period_end"`
	Start        int64             `json:"period_start"`
	StartBalance int64             `json:"starting_balance"`
	Subtotal     int64             `json:"subtotal"`
	Total        int64             `json:"total"`
	Fee          uint64            `json:"application_fee"`
	Charge       *Charge           `json:"charge"`
	Desc         string            `json:"description"`
	Discount     *Discount         `json:"discount"`
	EndBalance   int64             `json:"ending_balance"`
	NextAttempt  int64             `json:"next_payment_attempt"`
	Statement    string            `json:"statement_description"`
	Sub          string            `json:"subscription"`
	Webhook      int64             `json:"webhooks_delivered_at"`
	Meta         map[string]string `json:"metadata"`
}

// InvoiceLine is the resource representing a Stripe invoice line item.
// For more details see https://stripe.com/docs/api#invoice_line_item_object.
type InvoiceLine struct {
	Id        string            `json:"id"`
	Live      bool              `json:"live_mode"`
	Amount    int64             `json:"amount"`
	Currency  Currency          `json:"currency"`
	Period    *Period           `json:"period"`
	Proration bool              `json:"proration"`
	Type      InvoiceLineType   `json:"type"`
	Desc      string            `json:"description"`
	Meta      map[string]string `json:"metadata"`
	Plan      *Plan             `json:"plan"`
	Quantity  int64             `json:"quantity"`
}

// Period is a structure representing a start and end dates.
type Period struct {
	Start int64 `json:"start"`
	End   int64 `json:"end"`
}

// InvoiceLineList is a list object for invoice line items.
type InvoiceLineList struct {
	ListMeta
	Values []*InvoiceLine `json:"data"`
}

// InvoiceIter is a iterator for list responses.
type InvoiceIter struct {
	Iter *Iter
}

// Next returns the next value in the list.
func (i *InvoiceIter) Next() (*Invoice, error) {
	ii, err := i.Iter.Next()
	if err != nil {
		return nil, err
	}

	return ii.(*Invoice), err
}

// Stop returns true if there are no more iterations to be performed.
func (i *InvoiceIter) Stop() bool {
	return i.Iter.Stop()
}

// Meta returns the list metadata.
func (i *InvoiceIter) Meta() *ListMeta {
	return i.Iter.Meta()
}

// InvoiceLineIter is a iterator for list responses.
type InvoiceLineIter struct {
	Iter *Iter
}

// Next returns the next value in the list.
func (i *InvoiceLineIter) Next() (*InvoiceLine, error) {
	ii, err := i.Iter.Next()
	if err != nil {
		return nil, err
	}

	return ii.(*InvoiceLine), err
}

// Stop returns true if there are no more iterations to be performed.
func (i *InvoiceLineIter) Stop() bool {
	return i.Iter.Stop()
}

// Meta returns the list metadata.
func (i *InvoiceLineIter) Meta() *ListMeta {
	return i.Iter.Meta()
}

func (i *Invoice) UnmarshalJSON(data []byte) error {
	type invoice Invoice
	var ii invoice
	err := json.Unmarshal(data, &ii)
	if err == nil {
		*i = Invoice(ii)
	} else {
		// the id is surrounded by escaped \, so ignore those
		i.Id = string(data[1 : len(data)-1])
	}

	return nil
}
