package webhookmodels

type StripePlan struct {
	Name string `json:"name"`
}

type StripeSubscription struct {
	ID         string     `json:"id"`
	CustomerId string     `json:"customer"`
	Plan       StripePlan `json:"plan"`
}
