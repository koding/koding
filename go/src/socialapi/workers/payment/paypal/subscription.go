package paypal

import (
	"fmt"
	"socialapi/workers/payment/paymentmodels"
	"time"
)

func CreateSubscription(token string, plan *paymentmodels.Plan, customer *paymentmodels.Customer) error {
	digitalGoodName := fmt.Sprintf("%s-%s", plan.Title, plan.Interval)
	params := map[string]string{
		"PROFILESTARTDATE": time.Now().String(),
		"SUBSCRIBERNAME":   customer.OldId,
		"BILLINGPERIOD":    getInterval(plan.Interval),
		"AMT":              normalizeAmount(plan.AmountInCents),
		"BILLINGFREQUENCY": "1",
		"CURRENCYCODE":     CurrencyCode,
		"DESC":             digitalGoodName,
		"AUTOBILLOUTAMT":   "AddToNextBilling",
	}

	response, err := client.CreateRecurringPaymentsProfile(token, params)
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
