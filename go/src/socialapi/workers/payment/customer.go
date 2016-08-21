package payment

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"

	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/customer"
)

var (
	ErrCustomerNotSubscribedToAnyPlans = errors.New("user is not subscribed to any plans")
	ErrCustomerNotExists               = errors.New("user is not created for subscription")
)

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
