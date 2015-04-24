package webhookmodels

type StripePlan struct {
	ID       string  `json:"id"`
	Name     string  `json:"name"`
	Interval string  `json:"interval"`
	Amount   float64 `json:"amount"`
}

type StripeSubscription struct {
	ID                 string             `json:"id"`
	CustomerId         string             `json:"customer"`
	Plan               StripePlan         `json:"plan"`
	PreviousAttributes PreviousAttributes `json:"previous_attributes"`
}

type PreviousAttributes struct {
	Plan StripePlan `json:"plan"`
}

type StripePeriod struct {
	Start float64 `json:"start"`
	End   float64 `json:"end"`
}

type StripeInvoiceData struct {
	SubscriptionId string       `json:"id"`
	Period         StripePeriod `json:"period"`
	Plan           StripePlan   `json:"plan"`
}

type StripeInvoiceLines struct {
	Data  []StripeInvoiceData `json:"data"`
	Count int                 `json:"total_count"`
}

type StripeInvoice struct {
	ID         string             `json:"id"`
	CustomerId string             `json:"customer"`
	AmountDue  float64            `json:"amount_due"`
	Currency   string             `json:"currency"`
	Lines      StripeInvoiceLines `json:"lines"`
}

type StripeCard struct {
	Id      string `json:"id"`
	ExpYear string `json:"exp_year"`
	Last4   string `json:"last4"`
	Brand   string `json:"brand"`
}

type StripeCharge struct {
	Currency       string  `json:"currency"`
	CustomerId     string  `json:"customer"`
	Amount         float64 `json:"amount"`
	AmountRefunded float64 `json:"amount_refunded"`
}

type StripeCustomer struct {
	ID string `json:"id"`
}
