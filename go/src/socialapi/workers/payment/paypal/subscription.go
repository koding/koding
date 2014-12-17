package paypal

import (
	"socialapi/workers/payment/paymentmodels"
	"time"
)

func CreateSubscription(token string, plan *paymentmodels.Plan, customer *paymentmodels.Customer) error {
	client, err := Client()
	if err != nil {
		return err
	}

	params := map[string]string{
		"PROFILESTARTDATE":  time.Now().String(),
		"SUBSCRIBERNAME":    customer.OldId,
		"BILLINGPERIOD":     getInterval(plan.Interval),
		"AMT":               normalizeAmount(plan.AmountInCents),
		"BILLINGFREQUENCY":  "1",
		"CURRENCYCODE":      CurrencyCode,
		"DESC":              goodName(plan),
		"AUTOBILLOUTAMT":    "AddToNextBilling",
		"MAXFAILEDPAYMENTS": "3",
	}

	response, err := client.CreateRecurringPaymentsProfile(token, params)
	err = handlePaypalErr(response, err)

	if err != nil {
		Log.Warning("Failed to create recuring profile for customer: %v, deleting customer",
			customer.Username)

		custErr := customer.Delete()
		if custErr != nil {
			Log.Error("Failed to delete customer: %v", custErr)
		}

		return err
	}

	profileId := response.Values.Get("PROFILEID")

	subModel := &paymentmodels.Subscription{
		PlanId:                 plan.Id,
		CustomerId:             customer.Id,
		ProviderSubscriptionId: profileId,
		Provider:               ProviderName,
		State:                  "active",
		CurrentPeriodStart:     time.Now(),
		AmountInCents:          plan.AmountInCents,
	}
	err = subModel.Create()
	if err != nil {
		return err
	}

	return customer.UpdateProviderCustomerId(profileId)
}
