package webhookmodels

type StripePlan struct {
	Name string `json:"name"`
}

type StripeSubscription struct {
	ID         string     `json:"id"`
	CustomerId string     `json:"customer"`
	Plan       StripePlan `json:"plan"`
}

type StripeInvoice struct {
	ID         string  `json:"id"`
	CustomerId string  `json:"customer"`
	AmountDue  float64 `json:"amount_due"`
	Currency   string  `json:"currency"`
	Lines      struct {
		Data []struct {
			SubscriptionId string `json:"id"`
			Period         struct {
				Start float64 `json:"start"`
				End   float64 `json:"end"`
			} `json:"period"`
			Plan struct {
				Id   string `json:"id"`
				Name string `json:"name"`
			} `json:"plan"`
		} `json:"data"`
		Count int `json:"count"`
	} `json:"lines"`
}

type StripeCard struct {
	Id      string `json:"id"`
	ExpYear string `json:"exp_year"`
	Last4   string `json:"last4"`
	Brand   string `json:"brand"`
}

type StripeCharge struct {
	Card       *StripeCard `json:"card"`
	Currency   string      `json:"currency"`
	Amount     float64     `json:"amount"`
	CustomerId string      `json:"customer"`
}

type StripeCustomer struct {
	ID string `json:"id"`
}
