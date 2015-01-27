package paypal

import "socialapi/workers/payment/paymentmodels"

func ExpireIfUnPaid(providerCustomerId string) error {
	client, err := Client()
	if err != nil {
		return err
	}

	response, err := client.GetRecurringPaymentsProfileDetails(providerCustomerId)
	err = handlePaypalErr(response, err)
	if err != nil {
		return err
	}

	lastPaymentDate := response.Values.Get("LASTPAYMENTDATE")
	if lastPaymentDate == "" {
		return ExpireSubscription(providerCustomerId)
	}

	subscription, err := getSubscription(providerCustomerId)
	if err != nil {
		return err
	}

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
