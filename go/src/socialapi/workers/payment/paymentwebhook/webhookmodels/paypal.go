package webhookmodels

type PaypalGenericWebhook struct {
	TransactionType string `json:"txn_type"`
	Status          string `json:"payment_status"`
	PayerId         string `json:"payer_id"`
	Plan            string `json:"product_name"`
	Amount          string `json:"amount"`
	CurrencyCode    string `json:"current_code"`
}
