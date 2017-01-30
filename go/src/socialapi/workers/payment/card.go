package payment

import (
	"koding/db/mongodb/modelhelper"

	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/card"
)

// DeleteCreditCardForGroup deletes credit card of the group, if customer is not
// registered yet for the group, returns error. Credit card operations hanled by
// Stripe.
func DeleteCreditCardForGroup(groupName string) error {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return err
	}

	if group.Payment.Customer.ID == "" {
		return ErrCustomerNotExists
	}

	if err := deleteCreditCard(group.Payment.Customer.ID); err != nil {
		return err
	}

	return syncGroupWithCustomerID(group.Payment.Customer.ID)
}

// HasCreditCard checks if the given group has a credit card or not.
func HasCreditCard(groupName string) error {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return err
	}

	if group.Payment.Customer.ID == "" {
		return ErrCustomerNotExists
	}

	// sync updates the credit card info in the db.
	if err := syncGroupWithCustomerID(group.Payment.Customer.ID); err != nil {
		return err
	}

	// we need to fetch the group again to have the latest info.
	group, err = modelhelper.GetGroup(groupName)
	if err != nil {
		return err
	}

	if !group.Payment.Customer.HasCard {
		return ErrCustomerSourceNotExists
	}

	return nil
}

func deleteCreditCard(customerID string) error {
	params := &stripe.CardListParams{Customer: customerID}
	i := card.List(params)
	for i.Next() {
		c := i.Card()
		params := &stripe.CardParams{Customer: customerID}
		if _, err := card.Del(c.ID, params); err != nil {
			return err
		}
	}
	return i.Err()
}
