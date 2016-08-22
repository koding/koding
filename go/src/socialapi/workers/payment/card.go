package payment

import (
	"koding/db/mongodb/modelhelper"

	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/card"
	"github.com/stripe/stripe-go/customer"
)

// DeleteCreditCardForGroup deletes credit card of the group, if customer is not
// registered yet for the group, returns error. Credit card operations hanled by
// Stripe.
func DeleteCreditCardForGroup(groupName string) (*stripe.Card, error) {
	group, err := modelhelper.GetGroup(groupName)
	if err != nil {
		return nil, err
	}

	if group.Payment.Customer.ID == "" {
		return nil, ErrCustomerNotExists
	}

	return deleteCreditCard(group.Payment.Customer.ID)
}

func deleteCreditCard(customerID string) (*stripe.Card, error) {
	cus, err := customer.Get(customerID, nil)
	if err != nil {
		return nil, err
	}

	params := &stripe.CardParams{Customer: customerID}

	return card.Del(cus.DefaultSource.ID, params)
}
