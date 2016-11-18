package payment

import (
	"koding/db/mongodb/modelhelper"
	"time"

	stripe "github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/sub"
	"gopkg.in/mgo.v2/bson"
)

const (
	SubStatusTrailing stripe.SubStatus = "trialing"
	SubStatusActive   stripe.SubStatus = "active"
	SubStatusPastDue  stripe.SubStatus = "past_due"
	SubStatusCanceled stripe.SubStatus = "canceled"
	SubStatusUnpaid   stripe.SubStatus = "unpaid"
)

// CancelSubscriptionForGroup cancels the subscription for a team. In order to
// achive that, first deletes the current subscription then subscribes to new
// plan with new quantity, ( reasoning behind that is subscribing to a new plan
// charges immediately ) Then deletes the current subscription again. All these
// reqiured because we charge our users at the end of the month based  on the
// usage. So while cancelling group subscription, charge for the due usage
// amount immediately then cancel subscription
func CancelSubscriptionForGroup(groupName string) (interface{}, error) {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	info, err := GetInfoForGroup(group)
	if err != nil {
		return nil, err
	}

	if err := switchToNewSub(info); err != nil {
		return nil, err
	}

	return DeleteSubscriptionForGroup(groupName)
}

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

	if err := unsetSubData(group.Id); err != nil {
		return nil, err
	}

	return sub, nil
}

func unsetSubData(groupID bson.ObjectId) error {
	return modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": groupID},
		modelhelper.Selector{
			"$unset": modelhelper.Selector{
				"payment.subscription.id":     "",
				"payment.subscription.status": "",
			},
		},
	)
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

// EnsureSubscriptionForGroup ensures subscription for a group
func EnsureSubscriptionForGroup(groupName string, params *stripe.SubParams) (*stripe.Sub, error) {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	if group.Payment.Subscription.ID != "" {
		return sub.Get(group.Payment.Subscription.ID, nil)
	}

	if group.Payment.Customer.ID == "" {
		return nil, ErrCustomerNotExists
	}

	now := time.Now().UTC()
	thirtyDaysLater := now.Add(30 * 24 * time.Hour).Unix()
	sevenDaysLater := now.Add(7 * 24 * time.Hour).Unix()

	if params == nil {
		params = &stripe.SubParams{
			Customer: group.Payment.Customer.ID,
			Plan:     Plans[UpTo10Users].ID,
			TrialEnd: thirtyDaysLater,
		}
	}

	// we only allow 0, 7 and 30 day trials
	if params.TrialEnd < sevenDaysLater && params.TrialEnd != 0 {
		params.TrialEnd = sevenDaysLater
	}

	if params.TrialEnd > sevenDaysLater {
		params.TrialEnd = thirtyDaysLater
	}

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

	if err := setSubData(group.Id, sub); err != nil {
		return nil, err
	}

	return sub, nil
}

func setSubData(groupID bson.ObjectId, sub *stripe.Sub) error {
	return modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": groupID},
		modelhelper.Selector{
			"$set": modelhelper.Selector{
				"payment.subscription.id":     sub.ID,
				"payment.subscription.status": sub.Status,
			},
		},
	)
}
