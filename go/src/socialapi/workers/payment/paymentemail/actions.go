package paymentemail

type Action int

const (
	SubscriptionCreated Action = iota
	ChargeRefunded
	ChargeFailed
	SubscriptionDeleted
	InvoiceCreated
)
