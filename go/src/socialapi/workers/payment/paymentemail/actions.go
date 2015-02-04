package paymentemail

type Action int

const (
	SubscriptionCreated Action = iota
	SubscriptionDeleted
	PaymentCreated
	PaymentRefunded
	PaymentFailed
)
