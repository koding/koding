package paypal

import "socialapi/workers/payment/paymentmodels"

func CancelSubscription(customer *paymentmodels.Customer, subscription *paymentmodels.Subscription) error {
	return handleCancelation(customer, subscription)
}
