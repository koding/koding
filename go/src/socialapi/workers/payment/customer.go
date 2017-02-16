package payment

import (
	"errors"
	"fmt"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	socialapimodels "socialapi/models"

	stripe "github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/customer"
	stripeplan "github.com/stripe/stripe-go/plan"
	"golang.org/x/sync/errgroup"
)

var (
	// ErrCustomerNotSubscribedToAnyPlans error for not subscribed users
	ErrCustomerNotSubscribedToAnyPlans = errors.New("user is not subscribed to any plans")
	// ErrCustomerNotExists error for not created users
	ErrCustomerNotExists = errors.New("user is not created for subscription")
	// ErrGroupAlreadyHasSub error when a group tries to create a sub and they try to create another
	ErrGroupAlreadyHasSub = errors.New("group already has a subscription")
	// ErrCustomerSourceNotExists holds the error when a customer does not have a source
	ErrCustomerSourceNotExists = errors.New("does not have source")
)

// Usage holds current usage information, which will be calculated on the fly
type Usage struct {
	User            *UserInfo        `json:"user"`
	ExpectedPlan    *stripe.Plan     `json:"expectedPlan"`
	Due             uint64           `json:"due"`
	NextBillingDate time.Time        `json:"nextBillingDate"`
	Subscription    *stripe.Sub      `json:"subscription"`
	Customer        *stripe.Customer `json:"customer"`
	Trial           *TrialInfo       `json:"trialInfo"`
}

// UserInfo holds current info about team's user info
type UserInfo struct {
	Total int `json:"total"`
}

// TrialInfo holds trial's info about team
type TrialInfo struct {
	User         *UserInfo    `json:"user"`
	Due          uint64       `json:"due"`
	ExpectedPlan *stripe.Plan `json:"expectedPlan"`
}

// EnsureCustomerForGroup registers a customer for a group if it does not exist,
// returns the existing one if created previously
func EnsureCustomerForGroup(username string, groupName string, req *stripe.CustomerParams) (*stripe.Customer, error) {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	// if we already have the customer, return it.
	if group.Payment.Customer.ID != "" {
		return customer.Get(group.Payment.Customer.ID, nil)
	}

	req, err = populateCustomerParams(username, group.Slug, req)
	if err != nil {
		return nil, err
	}

	cus, err := customer.New(req)
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

// DeleteCustomerForGroup deletes the customer for a given group. If customer is
// not registered, returns error. If customer is already deleted, returns success.
// Not necessarily should be used. Call with care.
func DeleteCustomerForGroup(groupName string) error {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return err
	}

	if group.Payment.Customer.ID == "" {
		return nil
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

// UpdateCustomerForGroup updates customer data of a group
func UpdateCustomerForGroup(username, groupName string, params *stripe.CustomerParams) (*stripe.Customer, error) {
	if _, err := EnsureCustomerForGroup(username, groupName, params); err != nil {
		return nil, err
	}

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

	// if the update request has a new CC, delete old ones.
	if params != nil && params.Source != nil && params.Source.Token != "" {
		if err := DeleteCreditCardForGroup(groupName); err != nil {
			return nil, err
		}
	}

	cus, err := customer.Update(group.Payment.Customer.ID, params)
	if err != nil {
		return nil, err
	}

	if err := syncGroupWithCustomerID(group.Payment.Customer.ID); err != nil {
		return nil, err
	}

	return cus, err
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
	username := ""
	return EnsureInfoForGroup(group, username)
}

// EnsureInfoForGroup ensures data validity of the group, if customer does not
// exist, creates if, if sub does not exist, creates it
func EnsureInfoForGroup(group *models.Group, username string) (*Usage, error) {
	usage, err := fetchParallelizableUsageItems(group, username)
	if err != nil {
		return nil, err
	}

	var g errgroup.Group
	g.Go(func() error {
		expectedPlan, err := getPlan(usage.Subscription, usage.User.Total)
		if err != nil {
			return err
		}
		usage.ExpectedPlan = expectedPlan
		usage.Due = uint64(usage.User.Total) * expectedPlan.Amount
		return nil
	})

	g.Go(func() error {
		if usage.Trial.User.Total == 0 {
			return nil
		}
		trialPlan, err := getPlan(usage.Subscription, usage.Trial.User.Total)
		if err != nil {
			return err
		}
		usage.Trial.ExpectedPlan = trialPlan
		usage.Trial.Due = uint64(usage.Trial.User.Total) * trialPlan.Amount
		return nil
	})

	if err := g.Wait(); err != nil {
		return nil, err
	}

	return usage, nil
}

func fetchParallelizableUsageItems(group *models.Group, username string) (*Usage, error) {
	var g errgroup.Group

	var cus *stripe.Customer
	var subscription *stripe.Sub

	g.Go(func() (err error) {
		cus, err = EnsureCustomerForGroup(username, group.Slug, nil)
		if err != nil {
			return err
		}

		subscription, err = EnsureSubscriptionForGroup(group.Slug, nil)
		return err
	})

	// Active users count.
	var activeCount int
	g.Go(func() (err error) {
		activeCount, err = (&socialapimodels.PresenceDaily{}).CountDistinctByGroupName(group.Slug)
		return err
	})

	// Trialing user count is set if only sub is trialing.
	var trialCount int
	g.Go(func() (err error) {
		if group.Payment.Subscription.Status != "trialing" {
			return nil
		}

		trialCount, err = (&socialapimodels.PresenceDaily{}).CountDistinctProcessedByGroupName(group.Slug)
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
		Trial: &TrialInfo{
			User: &UserInfo{
				Total: trialCount,
			},
		},
	}

	return usage, nil
}

func getPlan(subscription *stripe.Sub, totalCount int) (*stripe.Plan, error) {
	plan := subscription.Plan

	expectedPlanID := GetPlanID(totalCount)
	// in the cases where the active subscription and the have-to-be
	// subscription is different, fetch the real plan from system. This can only
	// happen if the team got more members than the previous subscription's user
	// count in the current month. The subscription will be automatically fixed
	// on the next billing date. We do not change the subscription on each user
	// addition or deletion because Stripe charges the user whenever a
	// subscription change happens, so we only change the subscription on the
	// billing date with cancelling the previous subscription & invoice and
	// creating a new subscription with new requirement
	if plan.ID == expectedPlanID {
		return plan, nil
	}

	return stripeplan.Get(expectedPlanID, nil)
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
	if username == "" {
		return nil, socialapimodels.ErrNickIsNotSet
	}

	if groupName == "" {
		return nil, socialapimodels.ErrGroupNameIsNotSet
	}

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

// CheckCustomerHasSource checks if the given customer has any kind of active
// source.
func CheckCustomerHasSource(cusID string) error {
	cus, err := customer.Get(cusID, nil)
	if err != nil {
		return err
	}

	return checkCustomerHasSourceWithCustomer(cus)
}

func checkCustomerHasSourceWithCustomer(cus *stripe.Customer) error {
	if cus == nil {
		return ErrCustomerNotExists
	}

	if cus.Sources == nil {
		return ErrCustomerSourceNotExists
	}

	count := 0
	for _, source := range cus.Sources.Values {
		if !source.Deleted {
			count++
		}
	}

	if count == 1 {
		return nil
	}

	return ErrCustomerSourceNotExists
}
