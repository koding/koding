package stripe

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"time"

	"github.com/koding/bongo"
	stripe "github.com/stripe/stripe-go"
	stripeInvoice "github.com/stripe/stripe-go/invoice"
	stripeSub "github.com/stripe/stripe-go/sub"
)

func CreateSubscription(customer *paymentmodels.Customer, plan *paymentmodels.Plan) (*paymentmodels.Subscription, error) {
	subParams := &stripe.SubParams{
		Plan:     plan.ProviderPlanId,
		Customer: customer.ProviderCustomerId,
	}

	sub, err := stripeSub.New(subParams)
	if err != nil {
		return nil, handleStripeError(err)
	}

	start := time.Unix(sub.PeriodStart, 0)
	end := time.Unix(sub.PeriodEnd, 0)

	subModel := &paymentmodels.Subscription{
		PlanId:                 plan.Id,
		CustomerId:             customer.Id,
		ProviderSubscriptionId: sub.Id,
		Provider:               ProviderName,
		State:                  "active",
		CurrentPeriodStart:     start,
		CurrentPeriodEnd:       end,
		AmountInCents:          plan.AmountInCents,
	}
	err = subModel.Create()

	return subModel, err
}

func FindCustomerSubscriptions(customer *paymentmodels.Customer) ([]paymentmodels.Subscription, error) {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"customer_id": customer.Id,
		},
		Sort: map[string]string{
			"created_at": "DESC",
		},
	}

	return findCustomerSubscriptions(customer, query)
}

func FindCustomerActiveSubscriptions(customer *paymentmodels.Customer) ([]paymentmodels.Subscription, error) {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"customer_id": customer.Id,
			"state":       "active",
		},
		Sort: map[string]string{
			"created_at": "DESC",
		},
	}

	return findCustomerSubscriptions(customer, query)
}

func CancelSubscription(customer *paymentmodels.Customer, subscription *paymentmodels.Subscription) error {
	subParams := &stripe.SubParams{
		Customer: customer.ProviderCustomerId,
	}

	err := stripeSub.Cancel(subscription.ProviderSubscriptionId, subParams)
	if err != nil {
		Log.Error(err.Error())
	}

	return subscription.UpdateState(paymentmodels.SubscriptionStateCanceled)
}

func findCustomerSubscriptions(customer *paymentmodels.Customer, query *bongo.Query) ([]paymentmodels.Subscription, error) {
	var subscriptions = []paymentmodels.Subscription{}

	if customer.Id == 0 {
		return nil, paymenterrors.ErrCustomerIdIsNotSet
	}

	s := paymentmodels.Subscription{}
	err := s.Some(&subscriptions, query)
	if err != nil {
		return nil, err
	}

	if IsOverSubscribed(subscriptions) {
		Log.Error("Customer: %v has no too many subscriptions: %v", len(subscriptions))
	}

	return subscriptions, nil
}

func CancelSubscriptionAndRemoveCC(customer *paymentmodels.Customer, currentSubscription *paymentmodels.Subscription) error {
	err := CancelSubscription(customer, currentSubscription)
	if err != nil {
		return err
	}

	return RemoveCreditCard(customer)
}

func handleUpgrade(currentSubscription *paymentmodels.Subscription, customer *paymentmodels.Customer, plan *paymentmodels.Plan) error {
	subParams := &stripe.SubParams{
		Customer: customer.ProviderCustomerId,
		Plan:     plan.ProviderPlanId,
	}

	currentSubscriptionId := currentSubscription.ProviderSubscriptionId
	_, err := stripeSub.Update(currentSubscriptionId, subParams)
	if err != nil {
		return handleStripeError(err)
	}

	invoiceParams := &stripe.InvoiceParams{
		Customer: customer.ProviderCustomerId,
	}

	_, err = stripeInvoice.New(invoiceParams)
	if err != nil {
		stripeErr := handleStripeError(err)

		if !paymenterrors.IsNothingToInvoiceErr(stripeErr) {
			return stripeErr
		}
	}

	return currentSubscription.UpdatePlan(plan.Id, plan.AmountInCents)
}

// On downgrade, unlike upgrade, wait till end of the billing cycle to move to the new plan.
func handleDowngrade(currentSubscription *paymentmodels.Subscription, customer *paymentmodels.Customer, plan *paymentmodels.Plan) error {
	subParams := &stripe.SubParams{
		Customer: customer.ProviderCustomerId,
		Plan:     plan.ProviderPlanId,
	}

	currentSubscriptionId := currentSubscription.ProviderSubscriptionId
	_, err := stripeSub.Update(currentSubscriptionId, subParams)
	if err != nil {
		return handleStripeError(err)
	}

	return currentSubscription.UpdatePlan(plan.Id, plan.AmountInCents)
}
