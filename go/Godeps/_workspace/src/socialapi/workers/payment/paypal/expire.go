package paypal

import (
	"fmt"
	"socialapi/workers/payment/paymentmodels"
)

func ExpireBasedOnPayment(providerCustomerId string) error {
	client, err := Client()
	if err != nil {
		return err
	}

	response, err := client.GetRecurringPaymentsProfileDetails(providerCustomerId)
	err = handlePaypalErr(response, err)
	if err != nil {
		return err
	}

	// if user hasn't paid, expire right away
	lastPaymentDate := response.Values.Get("LASTPAYMENTDATE")
	if lastPaymentDate == "" {
		return ExpireSubscription(providerCustomerId)
	}

	subscription, err := getSubscription(providerCustomerId)
	if err != nil {
		return err
	}

	if subscription.CurrentPeriodEnd.IsZero() {
		return fmt.Errorf("Customer: %v expiration should be set at end of current period, but it is nil", providerCustomerId)
	}

	// user has paid for current period, so expire at end of period
	return subscription.UpdateToExpireTime(subscription.CurrentPeriodEnd)
}

func ExpireSubscription(providerCustomerId string) error {
	subscription, err := getSubscription(providerCustomerId)
	if err != nil {
		return err
	}

	return subscription.Expire()
}

func getSubscription(providerCustomerId string) (*paymentmodels.Subscription, error) {
	customer := paymentmodels.NewCustomer()
	err := customer.ByProviderCustomerId(providerCustomerId)
	if err != nil {
		return nil, err
	}

	subscription, err := customer.FindActiveSubscription()
	if err != nil {
		return nil, err
	}

	return subscription, nil
}
