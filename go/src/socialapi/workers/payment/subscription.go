package payment

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	socialapimodels "socialapi/models"
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
// achieve that, first deletes the current subscription then subscribes to new
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

	// remove all presence info for the group.
	if err := (&socialapimodels.PresenceDaily{}).DeleteByGroupName(groupName); err != nil {
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
			Plan: Solo,
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

	if err = CheckCustomerHasSource(group.Payment.Customer.ID); err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	// apply plan's default trial period
	if plan := GetPlan(params.Plan); plan != nil && plan.TrialPeriod != 0 {
		params.TrialEnd = now.Add(time.Duration(plan.TrialPeriod) * 24 * time.Hour).Unix()
	}

	// if group is not created within last ten minutes, subtract its duration from the trial end date
	groupCreatedAt := group.Id.Time().UTC()

	// 5 min is just a guestimate as a grace period.
	if params.TrialEnd != 0 && !groupCreatedAt.Add(time.Minute*5).After(now) {
		params.TrialEnd = params.TrialEnd - (now.Unix() - groupCreatedAt.Unix())
	}

	params.TrialEnd = normalizeTrialEnd(now, params.TrialEnd)

	// override quantity and plan in case we did not charge the user previously
	// due to failed payment and the subscription is deleted by stripe, create
	// new subscription
	quantity := uint64(1)
	activeCount, _ := (&socialapimodels.PresenceDaily{}).CountDistinctByGroupName(groupName)
	if activeCount != 0 {
		quantity = uint64(activeCount)
		params.Plan = GetPlanID(activeCount)
		params.TrialEnd = 0
	}

	// stripe API omits the zero values, force trial end.
	if params.TrialEnd == 0 {
		params.TrialEndNow = true
	}

	// only send our whitelisted params
	req := &stripe.SubParams{
		Customer:    group.Payment.Customer.ID,
		Quantity:    quantity,
		Plan:        params.Plan,
		Coupon:      params.Coupon,
		Token:       params.Token,
		TrialEnd:    params.TrialEnd,
		TrialEndNow: params.TrialEndNow,
		Card:        params.Card,
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

func normalizeTrialEnd(now time.Time, trialEnd int64) int64 {
	if trialEnd <= 0 {
		return 0
	}

	if now.Unix() > trialEnd {
		return 0
	}

	thirtyDaysLater := now.Add(30 * 24 * time.Hour).Unix()
	if trialEnd > thirtyDaysLater {
		return thirtyDaysLater
	}

	return trialEnd
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

	hasCard := checkCustomerHasSourceWithCustomer(cus) == nil

	// if subID and subStatus are same, update not needed
	if group.Payment.Subscription.ID == subID &&
		stripe.SubStatus(group.Payment.Subscription.Status) == subStatus &&
		group.Payment.Customer.HasCard == hasCard {
		return nil
	}

	return modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": group.Id},
		modelhelper.Selector{
			"$set": modelhelper.Selector{
				"payment.subscription.id":     subID,
				"payment.subscription.status": string(subStatus),
				"payment.customer.hasCard":    hasCard,
			},
		},
	)
}
