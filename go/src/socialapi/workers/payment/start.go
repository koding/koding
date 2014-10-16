package payment

import (
	"socialapi/workers/payment/paymentmodels"
	"time"
)

func InitCheckers() error {
	err := CheckForLeakedSubscriptions()
	if err != nil {
		Log.Error("Error checking for leaked subscriptions %v", err)
	}

	return err
}

func CheckForLeakedSubscriptions() error {
	thirtyDaysAgo := time.Now().Add(-30 * 24 * time.Hour)

	subscription := paymentmodel.NewSubscription()
	subscriptions, err := subscription.ByCanceledAtGte(thirtyDaysAgo)
	if err != nil {
		return err
	}

	subscriptionIds := []int64{}

	for _, subscription := range subscriptions {
		subscriptionIds = append(subscriptionIds, subscription.Id)
	}

	if len(subscriptions) > 0 {
		Log.Error(
			"%v subscriptions have been expired for more than 30 days. %v",
			len(subscriptionIds), subscriptionIds,
		)
	}

	return nil
}
