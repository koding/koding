package paypal

import "socialapi/workers/payment/paymentmodels"

func ExpireSubscription(providerCustomerId string) error {
	customer := paymentmodels.NewCustomer()
	err := customer.ByProviderCustomerId(providerCustomerId)
	if err != nil {
		return err
	}

	subscription, err := customer.FindActiveSubscription()
	if err != nil {
		return err
	}

	return subscription.Expire()
}
