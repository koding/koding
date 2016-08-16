package paymentclient

import (
	"github.com/stripe/stripe-go"
	"github.com/stripe/stripe-go/sub"
)

func DeleteSubscription(subscriptionId string) (*stripe.Sub, error) {
	sub, err := sub.Cancel(subscriptionId, nil)
	return sub, err
}

func UpdateSubscription(subscriptionId string, params *stripe.SubParams) (*stripe.Sub, error) {
	sub, err := sub.Update(
		subscriptionId,
		params,
	)
	return sub, err
	// s, err := sub.Update(
	//       "sub_8vthx3cIIf3Fk3",
	//       &stripe.SubParams{
	//         Plan: "gold",
	//       },
	//     )
	// &stripe.StripeObject JSON: {
	//   "id": "sub_8vthx3cIIf3Fk3",
	//   "object": "subscription",
	//   "application_fee_percent": null,
	//   "cancel_at_period_end": false,
	//   "canceled_at": null,
	//   "created": 1470140528,
	//   "current_period_end": 1501676528,
	//   "current_period_start": 1470140528,
	//   "customer": "cus_8vthMXVT3Fxgdq",
	//   "discount": null,
	//   "ended_at": null,
	//   "livemode": false,
	//   "metadata": {
	//   },
	//   "plan": {
	//     "id": "group8",
	//     "object": "plan",
	//     "amount": 0,
	//     "created": 1463962497,
	//     "currency": "usd",
	//     "interval": "year",
	//     "interval_count": 1,
	//     "livemode": false,
	//     "metadata": {
	//     },
	//     "name": "Group",
	//     "statement_descriptor": null,
	//     "trial_period_days": null
	//   },
	//   "quantity": 1,
	//   "start": 1470140528,
	//   "status": "active",
	//   "tax_percent": null,
	//   "trial_end": null,
	//   "trial_start": null
	// }
}

func GetSubscription(subscriptionId string) (*stripe.Sub, error) {
	sub, err := sub.Get(
		subscriptionId,
		nil,
	)

	return sub, err
	// s, err := sub.Get("sub_90k6ByUrg62p3T", nil)
	// &stripe.StripeObject JSON: {
	//   "id": "sub_8vthx3cIIf3Fk3",
	//   "object": "subscription",
	//   "application_fee_percent": null,
	//   "cancel_at_period_end": false,
	//   "canceled_at": null,
	//   "created": 1470140528,
	//   "current_period_end": 1501676528,
	//   "current_period_start": 1470140528,
	//   "customer": "cus_8vthMXVT3Fxgdq",
	//   "discount": null,
	//   "ended_at": null,
	//   "livemode": false,
	//   "metadata": {
	//   },
	//   "plan": {
	//     "id": "group8",
	//     "object": "plan",
	//     "amount": 0,
	//     "created": 1463962497,
	//     "currency": "usd",
	//     "interval": "year",
	//     "interval_count": 1,
	//     "livemode": false,
	//     "metadata": {
	//     },
	//     "name": "Group",
	//     "statement_descriptor": null,
	//     "trial_period_days": null
	//   },
	//   "quantity": 1,
	//   "start": 1470140528,
	//   "status": "active",
	//   "tax_percent": null,
	//   "trial_end": null,
	//   "trial_start": null
	// }
}

func CreateSubscription(params *stripe.SubParams) (*stripe.Sub, error) {
	s, err := sub.New(params)
	return s, err
	// s, err := sub.New(&stripe.SubParams{
	// 	Customer: "cus_8vthMXVT3Fxgdq",
	// 	Plan:     "gold",
	// })
	// &stripe.StripeObject JSON: {
	//   "id": "sub_8vthx3cIIf3Fk3",
	//   "object": "subscription",
	//   "application_fee_percent": null,
	//   "cancel_at_period_end": false,
	//   "canceled_at": null,
	//   "created": 1470140528,
	//   "current_period_end": 1501676528,
	//   "current_period_start": 1470140528,
	//   "customer": "cus_8vthMXVT3Fxgdq",
	//   "discount": null,
	//   "ended_at": null,
	//   "livemode": false,
	//   "metadata": {
	//   },
	//   "plan": {
	//     "id": "group8",
	//     "object": "plan",
	//     "amount": 0,
	//     "created": 1463962497,
	//     "currency": "usd",
	//     "interval": "year",
	//     "interval_count": 1,
	//     "livemode": false,
	//     "metadata": {
	//     },
	//     "name": "Group",
	//     "statement_descriptor": null,
	//     "trial_period_days": null
	//   },
	//   "quantity": 1,
	//   "start": 1470140528,
	//   "status": "active",
	//   "tax_percent": null,
	//   "trial_end": null,
	//   "trial_start": null
	// }
}
