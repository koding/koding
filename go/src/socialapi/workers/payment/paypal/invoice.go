package paypal

import "time"

func UpdateCurrentPeriods(providerCustomerId string, start, end time.Time) error {
	subscription, err := getSubscription(providerCustomerId)
	if err != nil {
		return err
	}

	return subscription.UpdateCurrentPeriods(start, end)
}
