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

	return deleteCreditCard(group.Payment.Customer.ID)
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
