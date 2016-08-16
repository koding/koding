package paymentclient

import (
	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/card"
	"github.com/stripe/stripe-go/customer"
)

func DeleteCustomer(customerId string) error {
	cus, err := customer.Del(customerId)
	if cus != nil && cus.Deleted { // if customer is already deleted previously
		return nil
	}

	return err
}

func UpdateCustomer(customerId string, params *stripe.CustomerParams) (*stripe.Customer, error) {
	sub, err := customer.Update(
		customerId,
		params,
	)
	return sub, err

	// c, err := customer.Update(
	//       "cus_90kKUTKxXxSJWH",
	//       &stripe.CustomerParams{Desc: "Customer for anthony.moore@example.com"},
	//     )
	// &stripe.Customer JSON: {
	//   "id": "cus_90kKUTKxXxSJWH",
	//   "object": "customer",
	//   "account_balance": 0,
	//   "created": 1471258863,
	//   "currency": "usd",
	//   "default_source": "card_18iiq32eZvKYlo2CcXR5Sxm7",
	//   "delinquent": false,
	//   "description": "Customer for anthony.moore@example.com",
	//   "discount": null,
	//   "email": null,
	//   "livemode": false,
	//   "metadata": {
	//   },
	//   "shipping": null,
	//   "sources": {
	//     "object": "list",
	//     "data": [
	//       {
	//         "id": "card_18iiq32eZvKYlo2CcXR5Sxm7",
	//         "object": "card",
	//         "address_city": null,
	//         "address_country": null,
	//         "address_line1": null,
	//         "address_line1_check": null,
	//         "address_line2": null,
	//         "address_state": null,
	//         "address_zip": null,
	//         "address_zip_check": null,
	//         "brand": "Visa",
	//         "country": "US",
	//         "customer": "cus_90kKUTKxXxSJWH",
	//         "cvc_check": "pass",
	//         "dynamic_last4": null,
	//         "exp_month": 12,
	//         "exp_year": 2017,
	//         "funding": "credit",
	//         "last4": "4242",
	//         "metadata": {
	//         },
	//         "name": null,
	//         "tokenization_method": null
	//       }
	//     ],
	//     "has_more": false,
	//     "total_count": 1,
	//     "url": "/v1/customers/cus_90kKUTKxXxSJWH/sources"
	//   },
	//   "subscriptions": {
	//     "object": "list",
	//     "data": [

	//     ],
	//     "has_more": false,
	//     "total_count": 0,
	//     "url": "/v1/customers/cus_90kKUTKxXxSJWH/subscriptions"
	//   }
	// }
}

func GetCustomer(customerId string) (*stripe.Customer, error) {
	cus, err := customer.Get(customerId, nil)

	return cus, err
	// c, err := customer.Get("cus_90kKUTKxXxSJWH", nil)
	// &stripe.Customer JSON: {
	//   "id": "cus_90kKUTKxXxSJWH",
	//   "object": "customer",
	//   "account_balance": 0,
	//   "created": 1471258863,
	//   "currency": "usd",
	//   "default_source": "card_18iiq32eZvKYlo2CcXR5Sxm7",
	//   "delinquent": false,
	//   "description": "Customer for some_external_id1",
	//   "discount": null,
	//   "email": null,
	//   "livemode": false,
	//   "metadata": {
	//   },
	//   "shipping": null,
	//   "sources": {
	//     "object": "list",
	//     "data": [
	//       {
	//         "id": "card_18iiq32eZvKYlo2CcXR5Sxm7",
	//         "object": "card",
	//         "address_city": null,
	//         "address_country": null,
	//         "address_line1": null,
	//         "address_line1_check": null,
	//         "address_line2": null,
	//         "address_state": null,
	//         "address_zip": null,
	//         "address_zip_check": null,
	//         "brand": "Visa",
	//         "country": "US",
	//         "customer": "cus_90kKUTKxXxSJWH",
	//         "cvc_check": "pass",
	//         "dynamic_last4": null,
	//         "exp_month": 12,
	//         "exp_year": 2017,
	//         "funding": "credit",
	//         "last4": "4242",
	//         "metadata": {
	//         },
	//         "name": null,
	//         "tokenization_method": null
	//       }
	//     ],
	//     "has_more": false,
	//     "total_count": 1,
	//     "url": "/v1/customers/cus_90kKUTKxXxSJWH/sources"
	//   },
	//   "subscriptions": {
	//     "object": "list",
	//     "data": [

	//     ],
	//     "has_more": false,
	//     "total_count": 0,
	//     "url": "/v1/customers/cus_90kKUTKxXxSJWH/subscriptions"
	//   }
	// }
}

func CreateCustomer(params *stripe.CustomerParams) (*stripe.Customer, error) {
	s, err := customer.New(params)
	return s, err

	// customerParams := &stripe.CustomerParams{
	//   Desc: "Customer for anthony.moore@example.com",
	// }
	// customerParams.SetSource("tok_189fO32eZvKYlo2CsJPvwfDn") // obtained with Stripe.js
	// c, err := customer.New(customerParams)
	// &stripe.Customer JSON: {
	//   "id": "cus_90kKUTKxXxSJWH",
	//   "object": "customer",
	//   "account_balance": 0,
	//   "created": 1471258863,
	//   "currency": "usd",
	//   "default_source": "card_18iiq32eZvKYlo2CcXR5Sxm7",
	//   "delinquent": false,
	//   "description": "Customer for some_external_id1",
	//   "discount": null,
	//   "email": null,
	//   "livemode": false,
	//   "metadata": {
	//   },
	//   "shipping": null,
	//   "sources": {
	//     "object": "list",
	//     "data": [
	//       {
	//         "id": "card_18iiq32eZvKYlo2CcXR5Sxm7",
	//         "object": "card",
	//         "address_city": null,
	//         "address_country": null,
	//         "address_line1": null,
	//         "address_line1_check": null,
	//         "address_line2": null,
	//         "address_state": null,
	//         "address_zip": null,
	//         "address_zip_check": null,
	//         "brand": "Visa",
	//         "country": "US",
	//         "customer": "cus_90kKUTKxXxSJWH",
	//         "cvc_check": "pass",
	//         "dynamic_last4": null,
	//         "exp_month": 12,
	//         "exp_year": 2017,
	//         "funding": "credit",
	//         "last4": "4242",
	//         "metadata": {
	//         },
	//         "name": null,
	//         "tokenization_method": null
	//       }
	//     ],
	//     "has_more": false,
	//     "total_count": 1,
	//     "url": "/v1/customers/cus_90kKUTKxXxSJWH/sources"
	//   },
	//   "subscriptions": {
	//     "object": "list",
	//     "data": [

	//     ],
	//     "has_more": false,
	//     "total_count": 0,
	//     "url": "/v1/customers/cus_90kKUTKxXxSJWH/subscriptions"
	//   }
	// }
}

func DeleteCreditCard(customerID string) (*stripe.Card, error) {
	cus, err := GetCustomer(customerID)
	if err != nil {
		return nil, err
	}

	c, err := card.Del(
		cus.DefaultSource.ID,
		&stripe.CardParams{
			Customer: customerID,
		},
	)
	if err != nil {
		return nil, err
	}

	return c, nil
}
