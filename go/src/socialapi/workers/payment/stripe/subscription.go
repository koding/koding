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

var (
	SubscriptionStateActive   = "active"
	SubscriptionStateCanceled = "canceled"
	SubscriptionStateExpired  = "expired"
)

func CreateSubscription(customer *paymentmodel.Customer, plan *paymentmodel.Plan) (*paymentmodel.Subscription, error) {
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

	subModel := &paymentmodel.Subscription{
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
	if err != nil {
		return nil, err
	}

	return subModel, nil
}

func FindCustomerSubscriptions(customer *paymentmodel.Customer) ([]paymentmodel.Subscription, error) {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"customer_id": customer.Id,
		},
	}

	return _findCustomerSubscriptions(customer, query)
}

func FindCustomerActiveSubscriptions(customer *paymentmodel.Customer) ([]paymentmodel.Subscription, error) {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"customer_id": customer.Id,
			"state":       "active",
		},
	}

	return _findCustomerSubscriptions(customer, query)
}

func CancelSubscription(customer *paymentmodel.Customer, subscription *paymentmodel.Subscription) error {
	subParams := &stripe.SubParams{
		Customer: customer.ProviderCustomerId,
	}

	err := stripeSub.Cancel(subscription.ProviderSubscriptionId, subParams)
	if err != nil {
		return handleStripeError(err)
	}

	err = subscription.UpdateState(SubscriptionStateCanceled)
	if err != nil {
		return err
	}

	return nil
}

func _findCustomerSubscriptions(customer *paymentmodel.Customer, query *bongo.Query) ([]paymentmodel.Subscription, error) {
	var subs = []paymentmodel.Subscription{}

	if customer.Id == 0 {
		return nil, paymenterrors.ErrCustomerIdIsNotSet
	}

	s := paymentmodel.Subscription{}
	err := s.Some(&subs, query)
	if err != nil {
		return nil, err
	}

	return subs, nil
}

func CancelSubscriptionAndRemoveCC(customer *paymentmodel.Customer, currentSubscription *paymentmodel.Subscription) error {
	err := CancelSubscription(customer, currentSubscription)
	if err != nil {
		return err
	}

	err = RemoveCreditCard(customer)
	if err != nil {
		return err
	}

	return nil
}

func UpdateSubscriptionForCustomer(customer *paymentmodel.Customer, subscriptions []paymentmodel.Subscription, plan *paymentmodel.Plan) error {
	subParams := &stripe.SubParams{
		Customer: customer.ProviderCustomerId,
		Plan:     plan.ProviderPlanId,
	}

	if IsNoSubscriptions(subscriptions) {
		return paymenterrors.ErrCustomerNotSubscribedToAnyPlans
	}

	currentSubscription := subscriptions[0]
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
		return err
	}

	err = currentSubscription.UpdatePlan(plan.Id, plan.AmountInCents)
	if err != nil {
		return err
	}

	return err
}
