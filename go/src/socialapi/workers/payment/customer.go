package payment

import (
	"errors"
	"fmt"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	socialapimodels "socialapi/models"
	"time"

	"gopkg.in/mgo.v2/bson"

	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/customer"
	stripeplan "github.com/stripe/stripe-go/plan"
	"github.com/stripe/stripe-go/sub"
	"golang.org/x/sync/errgroup"
)

var (
	// ErrCustomerNotSubscribedToAnyPlans error for not subscribed users
	ErrCustomerNotSubscribedToAnyPlans = errors.New("user is not subscribed to any plans")
	// ErrCustomerNotExists error for not created users
	ErrCustomerNotExists = errors.New("user is not created for subscription")
	// ErrGroupAlreadyHasSub error when a group tries to create a sub and they try to create another
	ErrGroupAlreadyHasSub = errors.New("group already has a subscription")
)

// Usage holds current usage information, which will be calculated on the fly
type Usage struct {
	User            *UserInfo
	ExpectedPlan    *stripe.Plan
	Due             uint64
	NextBillingDate time.Time
	Subscription    *stripe.Sub
	Customer        *stripe.Customer
}

// UserInfo holds current info about team's user info
type UserInfo struct {
	Total   int
	Active  int
	Deleted int
}

// DeleteCustomerForGroup deletes the customer for a given group. If customer is
// not registered, returns error. If customer is already deleted, returns success.
func DeleteCustomerForGroup(groupName string) error {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return err
	}

	if group.Payment.Customer.ID == "" {
		return ErrCustomerNotExists
	}

	if err := deleteCustomer(group.Payment.Customer.ID); err != nil {
		return err
	}

	return modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": group.Id},
		modelhelper.Selector{
			// deleting customer deletes everything belong to that customer in stripe,
			// so say we all
			"$unset": modelhelper.Selector{"payment": ""},
		},
	)
}

// UpdateCustomerForGroup updates customer data of a group`
func UpdateCustomerForGroup(username, groupName string, params *stripe.CustomerParams) (*stripe.Customer, error) {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	if group.Payment.Customer.ID == "" {
		return nil, ErrCustomerNotExists
	}

	params, err = populateCustomerParams(username, groupName, params)
	if err != nil {
		return nil, err
	}

	return customer.Update(group.Payment.Customer.ID, params)
}

// GetCustomerForGroup get the registered customer info of a group if exists
func GetCustomerForGroup(groupName string) (*stripe.Customer, error) {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	if group.Payment.Customer.ID == "" {
		return nil, ErrCustomerNotExists
	}

	return customer.Get(group.Payment.Customer.ID, nil)
}

// GetInfoForGroup get the current usage info of a group
func GetInfoForGroup(group *models.Group) (*Usage, error) {
	usage, err := fetchParallelizableeUsageItems(group)
	if err != nil {
		return nil, err
	}

	plan, err := getPlan(usage.Subscription, usage.User.Total)
	if err != nil {
		return nil, err
	}

	usage.ExpectedPlan = plan
	usage.Due = uint64(usage.User.Total) * plan.Amount

	return usage, nil

}

func fetchParallelizableeUsageItems(group *models.Group) (*Usage, error) {
	var g errgroup.Group

	// Stripe customer.
	var cus *stripe.Customer
	g.Go(func() (err error) {
		if group.Payment.Customer.ID == "" {
			return ErrCustomerNotExists
		}

		cus, err = customer.Get(group.Payment.Customer.ID, nil)
		return err
	})

	// Stripe subscription.
	var subscription *stripe.Sub
	g.Go(func() (err error) {
		if group.Payment.Subscription.ID == "" {
			return ErrCustomerNotSubscribedToAnyPlans
		}

		subscription, err = sub.Get(group.Payment.Subscription.ID, nil)
		return err
	})

	// Active users count.
	var activeCount int
	g.Go(func() (err error) {
		activeCount, err = (&socialapimodels.PresenceDaily{}).CountDistinctByGroupName(group.Slug)
		return err
	})

	if err := g.Wait(); err != nil {
		return nil, err
	}

	usage := &Usage{
		User: &UserInfo{
			Total: activeCount,
		},
		ExpectedPlan:    nil,
		Due:             0,
		NextBillingDate: time.Unix(subscription.PeriodEnd, 0),
		Subscription:    subscription,
		Customer:        cus,
	}

	return usage, nil
}

func getPlan(subscription *stripe.Sub, totalCount int) (*stripe.Plan, error) {
	plan := subscription.Plan

	if plan.Amount == 0 { // we are on trial period
		return plan, nil
	}

	// in the cases where the active subscription and the have-to-be
	// subscription is different, fetch the real plan from system. This can only
	// happen if the team got more members than the previous subscription's user
	// count in the current month. The subscription will be automatically fixed
	// on the next billing date. We do not change the subscription on each user
	// addition or deletion becasue Stripe charges the user whenever a
	// subscription change happens, so we only change the subscription on the
	// billing date with cancelling the previous subscription & invoice and
	// creating a new subscription with new requirement
	if plan.ID == GetPlanID(totalCount) {
		return plan, nil
	}

	return stripeplan.Get(GetPlanID(totalCount), nil)
}

func createFilter(groupID bson.ObjectId) modelhelper.Selector {
	return modelhelper.Selector{
		"as":         modelhelper.Selector{"$in": []string{"owner", "admin", "member"}},
		"targetName": "JAccount",
		"sourceName": "JGroup",
		"sourceId":   groupID,
	}
}

// CreateCustomerForGroup registers a customer for a group
func CreateCustomerForGroup(username, groupName string, req *stripe.CustomerParams) (*stripe.Customer, error) {
	req, err := populateCustomerParams(username, groupName, req)
	if err != nil {
		return nil, err
	}

	cus, err := customer.New(req)
	if err != nil {
		return nil, err
	}

	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	if err := modelhelper.UpdateGroupPartial(
		modelhelper.Selector{"_id": group.Id},
		modelhelper.Selector{
			"$set": modelhelper.Selector{
				"payment.customer.id": cus.ID,
			},
		},
	); err != nil {
		return nil, err
	}

	return cus, nil
}

// deleteCustomer tries to make customer deletion idempotent
func deleteCustomer(customerID string) error {
	cus, err := customer.Del(customerID)
	if cus != nil && cus.Deleted { // if customer is already deleted previously
		return nil
	}

	return err
}

func populateCustomerParams(username, groupName string, initial *stripe.CustomerParams) (*stripe.CustomerParams, error) {
	if initial == nil {
		initial = &stripe.CustomerParams{}
	}

	// whitelisted parameters
	req := &stripe.CustomerParams{
		Token:  initial.Token,
		Coupon: initial.Coupon,
		Source: initial.Source,
		Desc:   initial.Desc,
		Email:  initial.Email,
		Params: initial.Params,
		// plan can not be updated by hand, do not add it to whilelist. It should
		// only be updated automatically on invoice applications
		// Plan: initial.Plan,
	}

	user, err := modelhelper.GetUser(username)
	if err != nil {
		return nil, err
	}

	if req.Desc == "" {
		req.Desc = fmt.Sprintf("%s team", groupName)
	}
	if req.Email == "" {
		req.Email = user.Email
	}

	if req.Params.Meta == nil {
		req.Params.Meta = make(map[string]string)
	}
	req.Params.Meta["groupName"] = groupName
	req.Params.Meta["username"] = username

	return req, nil
}
