package paypal

import (
	"socialapi/workers/payment/paymentmodels"
	"time"

	"github.com/koding/paypal"
)

func CreateSubscription(token string, plan *paymentmodels.Plan, customer *paymentmodels.Customer) error {
	args := paypal.NewExpressCheckoutSingleArgs()
	args.ReturnURL = returnURL
	args.CancelURL = cancelURL
	args.Item = paypal.NewDigitalGood(plan.Title, 0)

	response, err := client.SetExpressCheckoutSingle(args)
	err = handlePaypalErr(response, err)
	if err != nil {
		return err
	}

	params := map[string]string{
		"PROFILESTARTDATE": time.Now().String(),
		"SUBSCRIBERNAME":   customer.OldId,
		"BILLINGPERIOD":    getInterval(plan.Interval),
		"AMT":              normalizeAmount(plan.AmountInCents),
		"BILLINGFREQUENCY": "1",
		"CURRENCYCODE":     CurrencyCode,
		"DESC":             plan.Title,
		"AUTOBILLOUTAMT":   "AddToNextBilling",
	}

	response, err = client.CreateRecurringPaymentsProfile(token, params)
	err = handlePaypalErr(response, err)
	if err != nil {
		return err
	}

	subModel := &paymentmodels.Subscription{
		PlanId:                 plan.Id,
		CustomerId:             customer.Id,
		ProviderSubscriptionId: response.Values.Get("PROFILEID"),
		Provider:               ProviderName,
		State:                  "active",
		CurrentPeriodStart:     time.Now(),
		AmountInCents:          plan.AmountInCents,
	}
	err = subModel.Create()

	return err
}
