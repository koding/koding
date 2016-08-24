package payment

import (
	"koding/db/mongodb/modelhelper"

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

	sub, err := deleteSubscription(group.Payment.Subscription.ID)
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

func deleteSubscription(subscriptionID string) (*stripe.Sub, error) {
	sub, err := sub.Cancel(subscriptionID, nil)
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

	sub, err := sub.New(params)
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
