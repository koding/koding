package payment

import (
	"koding/db/mongodb/modelhelper"
	"time"

	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/sub"
)

// DeleteSubscriptionForGroup deletes the subscription of a group
func DeleteSubscriptionForGroup(groupName string) (*stripe.Sub, error) {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	if group.Payment.Subscription.ID == "" {
		return nil, ErrCustomerNotSubscribedToAnyPlans
	}

	if group.Payment.Customer.ID == "" {
		return nil, ErrCustomerNotExists
	}

	sub, err := deleteSubscription(group.Payment.Subscription.ID, group.Payment.Customer.ID)
	if err != nil {
		return nil, err
	}

	if err := modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": group.Id},
		modelhelper.Selector{
			"$unset": modelhelper.Selector{
				"payment.subscription.id":     sub.ID,
				"payment.subscription.status": sub.Status,
			},
		},
	); err != nil {
		return nil, err
	}

	return sub, nil
}

func deleteSubscription(subscriptionID, customerID string) (*stripe.Sub, error) {
	sub, err := sub.Cancel(subscriptionID, &stripe.SubParams{Customer: customerID})
	if sub != nil && sub.Status == "canceled" {
		return sub, nil
	}

	return sub, err
}

// GetSubscriptionForGroup gets the subscription of a group
func GetSubscriptionForGroup(groupName string) (*stripe.Sub, error) {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	if group.Payment.Subscription.ID == "" {
		return nil, ErrCustomerNotSubscribedToAnyPlans
	}

	return sub.Get(group.Payment.Subscription.ID, nil)
}

// CreateSubscriptionForGroup creates a subscription for a group
func CreateSubscriptionForGroup(groupName string, params *stripe.SubParams) (*stripe.Sub, error) {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	if group.Payment.Subscription.ID != "" {
		return nil, ErrGroupAlreadyHasSub
	}

	if group.Payment.Customer.ID == "" {
		return nil, ErrCustomerNotExists
	}

	thirtDaysLater := time.Now().UTC().Add(30 * 24 * time.Hour).Unix()
	// this might be changed in the future
	if params.TrialEnd > thirtDaysLater {
		params.TrialEnd = thirtDaysLater
	}

	// // TODO(cihangir): remove this when client side fixes the request
	// if params.TrialEnd == 0 {
	// 	// set 7 days
	// 	params.TrialEnd = time.Now().UTC().Add(7 * 24 * time.Hour).Unix()
	// }

	// only send our whitelisted params
	req := &stripe.SubParams{
		Customer: group.Payment.Customer.ID,
		Plan:     params.Plan,
		Coupon:   params.Coupon,
		Token:    params.Token,
		TrialEnd: params.TrialEnd,
		Card:     params.Card,
	}

	sub, err := sub.New(req)
	if err != nil {
		return nil, err
	}

	if err := modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": group.Id},
		modelhelper.Selector{
			"$set": modelhelper.Selector{
				"payment.subscription.id":     sub.ID,
				"payment.subscription.status": sub.Status,
			},
		},
	); err != nil {
		return nil, err
	}

	return sub, nil
}
