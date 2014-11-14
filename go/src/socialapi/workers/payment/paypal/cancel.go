package paypal

import (
	"socialapi/workers/payment/paymentmodels"

	"github.com/koding/paypal"
)

func CancelSubscription(providerCustomerId string) error {
	customer := paymentmodels.NewCustomer()
	err := customer.ByProviderCustomerId(providerCustomerId)
	if err != nil {
		return err
	}

	response, err := client.ManageRecurringPaymentsProfileStatus(
		customer.ProviderCustomerId, paypal.Cancel,
	)
	err = handlePaypalErr(response, err)
	if err != nil {
		return err
	}

	subscription, err := customer.FindActiveSubscription()
	if err != nil {
		return err
	}

	return subscription.Cancel()
}
