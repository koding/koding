package paymentemail

type Action int

const (
	SubscriptionCreated Action = iota
	ChargeRefunded      Action = iota
	ChargeFailed        Action = iota
	SubscriptionDeleted Action = iota
	InvoiceCreated      Action = iota
)
