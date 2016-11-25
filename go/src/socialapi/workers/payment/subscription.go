package payment

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"time"

	stripe "github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/customer"
	"github.com/stripe/stripe-go/sub"
	mgo "gopkg.in/mgo.v2"
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
func CancelSubscriptionForGroup(groupName string) (*stripe.Sub, error) {
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

	if err := syncGroupWithCustomerID(group.Payment.Customer.ID); err != nil {
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

// EnsureSubscriptionForGroup ensures subscription for a group
func EnsureSubscriptionForGroup(groupName string, params *stripe.SubParams) (*stripe.Sub, error) {
	if params == nil {
		params = &stripe.SubParams{
			Plan: Plans[UpTo10Users].ID,
		}
	}

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

	hasSource, err := checkCustomerHasSource(group.Payment.Customer.ID)
	if err != nil {
		return nil, err
	}

	if !hasSource {
		return nil, ErrCustomerSourceNotExists
	}

	now := time.Now().UTC()
	thirtyDaysLater := now.Add(30 * 24 * time.Hour).Unix()
	sevenDaysLater := now.Add(7 * 24 * time.Hour).Unix()

	if params.TrialEnd != 0 {
		// we only allow 0, 7 and 30 day trials
		if params.TrialEnd < sevenDaysLater {
			params.TrialEnd = sevenDaysLater
		}

		if params.TrialEnd > sevenDaysLater {
			params.TrialEnd = thirtyDaysLater
		}
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

	if err := syncGroupWithCustomerID(group.Payment.Customer.ID); err != nil {
		return nil, err
	}

	return sub, nil
}

func syncGroupWithCustomerID(cusID string) error {
	cus, err := customer.Get(cusID, nil)
	if err != nil {
		return err
	}

	group, err := modelhelper.GetGroup(cus.Meta["groupName"])
	if err == mgo.ErrNotFound {
		return nil
	}

	if err != nil {
		return err
	}

	// here sub count might be 0, but should not be gt 1
	if cus.Subs.Count > 1 {
		return errors.New("customer should only have one subscription")
	}

	subID := ""
	subStatus := SubStatusCanceled

	// if we dont have any sub, set it as canceled
	if cus.Subs.Count == 1 {
		subID = cus.Subs.Values[0].ID
		subStatus = cus.Subs.Values[0].Status
	}

	// if subID and subStatus are same, update not needed
	if group.Payment.Subscription.ID == subID &&
		group.Payment.Subscription.Status == string(subStatus) {
		return nil
	}

	return modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": group.Id},
		modelhelper.Selector{
			"$set": modelhelper.Selector{
				"payment.subscription.id":     subID,
				"payment.subscription.status": string(subStatus),
			},
		},
	)
}
