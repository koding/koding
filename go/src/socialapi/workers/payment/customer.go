package payment

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/helpers"
	"sync"
	"time"

	"gopkg.in/fatih/set.v0"
	"gopkg.in/mgo.v2/bson"

	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/customer"
	"github.com/stripe/stripe-go/sub"
)

var (
	// ErrCustomerNotSubscribedToAnyPlans error for not subscribed users
	ErrCustomerNotSubscribedToAnyPlans = errors.New("user is not subscribed to any plans")
	// ErrCustomerNotExists error for not created users
	ErrCustomerNotExists = errors.New("user is not created for subscription")
)

type Usage struct {
	User            *UserInfo
	Plan            *stripe.Plan
	Due             uint64
	NextBillingDate time.Time
	Subscription    *stripe.Sub
}

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
			"$unset": modelhelper.Selector{"payment.customer.id": ""},
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
func GetInfoForGroup(groupName string) (*Usage, error) {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	if group.Payment.Customer.ID == "" {
		return nil, ErrCustomerNotExists
	}

	if group.Payment.Subscription.ID == "" {
		return nil, ErrCustomerNotSubscribedToAnyPlans
	}

	var infoErr error
	var errMu sync.RWMutex
	var wg sync.WaitGroup

	withCheck := func(f func() error) {
		errMu.RLock()
		if infoErr != nil {
			errMu.RUnlock()
			return
		}
		errMu.RUnlock()

		err := f()
		if err != nil {
			errMu.Lock()
			infoErr = err
			errMu.Unlock()
		}
		wg.Done()
	}

	var cus *stripe.Customer
	wg.Add(1)
	go withCheck(func() (err error) {
		cus, err = customer.Get(group.Payment.Customer.ID, nil)
		return err
	})

	var subscription *stripe.Sub
	wg.Add(1)
	go withCheck(func() (err error) {
		subscription, err = sub.Get(group.Payment.Subscription.ID, nil)
		return err
	})

	var activeCount int
	wg.Add(1)
	go withCheck(func() (err error) {
		activeCount, err = calculateActiveUserCount(group.Id)
		return err
	})

	var deletedCount int
	wg.Add(1)
	go withCheck(func() (err error) {
		deletedCount, err = calculateDeletedUserCount(group.Id)
		return err
	})

	wg.Wait()

	if infoErr != nil {
		return nil, infoErr
	}

	p := Plans[0]
	totalCount := activeCount + deletedCount

	usage := &Usage{
		User: &UserInfo{
			Total:   totalCount,
			Active:  activeCount,
			Deleted: deletedCount,
		},
		Plan:            nil,
		Due:             uint64(totalCount) * p.Amount,
		NextBillingDate: time.Now(),
		Subscription:    subscription,
	}

	return usage, nil

}

func createFilter(groupID bson.ObjectId) modelhelper.Selector {
	return modelhelper.Selector{
		"as":         modelhelper.Selector{"$in": []string{"owner", "admin", "member"}},
		"targetName": "JAccount",
		"sourceName": "JGroup",
		"sourceId":   groupID,
	}
}

// calculateActiveUserCount calculates the active user count from the
// relationship collection. I tried using map-reduce first but that was so
// magical from  engineering perspective and we dont have any other usage of it
// in our system. Then i implemented it using "aggregate" framework, that worked
// pretty well indeed but it is fetching all the records from database at once,
// so decided to use our battle tested iter support, it handles iterations, bulk
// operations, timeouts. We are actively using it for iterating over millions of
// records without hardening on the database.
//
//
// Sample aggregate function
//
// db.relationships.aggregate([
//     { "$match": { as: { $in : [ "owner", "admin", "member" ] }, targetName:"JAccount", sourceName:"JGroup", sourceId: ObjectId("") }},
//     // Count all occurrences
//     { "$group": {
//         "_id": {
//             "targetId": "$targetId"
//         },
//         "count": { "$sum": 1 }
//     }},
//     // Sum all occurrences and count distinct
//     { "$group": {
//         "_id": {
//             "targetId": "$_id.targetId"
//         },
//         "totalCount": { "$sum": "$count" },
//         "distinctCount": { "$sum": 1 }
//     }}
// ])
//
func calculateActiveUserCount(groupID bson.ObjectId) (int, error) {

	accounts := set.New()
	iterOptions := helpers.NewIterOptions()
	iterOptions.F = func(rel interface{}) error {
		result, ok := rel.(*models.Relationship)
		if !ok {
			return errors.New("not a relationship data")
		}
		accounts.Add(result.TargetId)
		return nil
	}
	iterOptions.CollectionName = modelhelper.RelationshipColl
	iterOptions.Filter = createFilter(groupID)
	iterOptions.Result = &models.Relationship{}
	iterOptions.Limit = 0
	iterOptions.Skip = 0
	// iterOptions.Log = log

	err := helpers.Iter(modelhelper.Mongo, iterOptions)
	if err != nil {
		return 0, err
	}

	return accounts.Size(), nil
}

func calculateDeletedUserCount(groupID bson.ObjectId) (int, error) {
	return modelhelper.GetDeletedMemberCountByGroupId(groupID)
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

func deleteCustomer(customerID string) error {
	cus, err := customer.Del(customerID)
	if cus != nil && cus.Deleted { // if customer is already deleted previously
		return nil
	}

	return err
}

func populateCustomerParams(username, groupName string, req *stripe.CustomerParams) (*stripe.CustomerParams, error) {
	if req == nil {
		req = &stripe.CustomerParams{}
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
