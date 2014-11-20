package payment

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/paypal"
	"socialapi/workers/payment/stripe"
	"time"

	"github.com/koding/bongo"
)

func Initialize(conf *config.Config) {
	stripe.InitializeClientKey(conf.Stripe.SecretToken)
	paypal.InitializeClientKey(conf.Paypal)

	go func() {
		err := stripe.CreateDefaultPlans()
		if err != nil {
			fmt.Println(err)
			panic(err)
		}
	}()

	go InitCheckers()
}

func InitCheckers() error {
	err := CheckForLeakedSubscriptions()
	if err != nil {
		Log.Error("Error checking for leaked subscriptions %v", err)
	}

	return err
}

func CheckForLeakedSubscriptions() error {
	thirtyDaysAgo := time.Now().Add(-30 * 24 * time.Hour)

	subscription := paymentmodels.NewSubscription()
	subscriptions, err := subscription.ByCanceledAtGte(thirtyDaysAgo)
	if err != nil {
		if err == bongo.RecordNotFound {
			return nil
		}

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
