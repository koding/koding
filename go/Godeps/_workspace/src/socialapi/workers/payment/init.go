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

	go func() {
		InitCheckers()

		ticker := time.NewTicker(time.Hour * 1)
		for _ = range ticker.C {
			InitCheckers()
		}
	}()
}

func InitCheckers() error {
	err := CheckForLeakedSubscriptions()
	if err != nil {
		Log.Error(fmt.Sprintf("Error checking for leaked subscriptions: %v", err))
		return err
	}

	err = ExpireOutofDateSubscriptions()
	if err != nil {
		Log.Error(fmt.Sprintf("Error expiring out of date subscriptions: %v", err))
		return err
	}

	return nil
}

func CheckForLeakedSubscriptions() error {
	thirtyDaysAgo := time.Now().Add(-30 * 24 * time.Hour)

	subscription := paymentmodels.NewSubscription()
	subscriptions, err := subscription.ByCanceledAtGte(thirtyDaysAgo)
	if err != nil {
		return handleBongoError(err)
	}

	subscriptionIds := []int64{}

	for _, s := range subscriptions {
		subscriptionIds = append(subscriptionIds, s.Id)
	}

	if len(subscriptions) > 0 {
		Log.Error(
			"%v subscriptions have been expired for more than 30 days. %v",
			len(subscriptionIds), subscriptionIds,
		)
	}

	return nil
}

func ExpireOutofDateSubscriptions() error {
	subscription := paymentmodels.NewSubscription()
	subscriptions, err := subscription.ByExpiredAtAndNotExpired(time.Now().UTC())
	if err != nil {
		return handleBongoError(err)
	}

	for _, s := range subscriptions {
		err = s.Expire()
		if err != nil {
			Log.Error(fmt.Sprintf("Error expiring out of date subscription: %v %v",
				s.Id, err.Error()),
			)
		}
	}

	return nil
}

func handleBongoError(err error) error {
	if err != nil && err == bongo.RecordNotFound {
		return nil
	}

	return err
}
