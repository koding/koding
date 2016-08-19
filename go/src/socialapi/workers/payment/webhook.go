package payment

import "socialapi/workers/payment/paymentwebhook/webhookmodels"

//----------------------------------------------------------
// SubscriptionDeleted
//----------------------------------------------------------

func SubscriptionDeletedWebhook(req *webhookmodels.StripeSubscription) error {
	// subscription := paymentmodels.NewSubscription()
	// if err := subscription.ByProviderId(req.ID, ProviderName); err != nil {
	// 	return err
	// }

	// if subscription.State == paymentmodels.SubscriptionStateActive {
	// 	subscription.Expire()
	// }

	// customer := paymentmodels.NewCustomer()
	// if err := customer.ById(subscription.CustomerId); err != nil {
	// 	return err
	// }

	// return RemoveCreditCard(customer)
	return nil
}

//----------------------------------------------------------
// InvoiceCreated
//----------------------------------------------------------

func InvoiceCreatedWebhook(req *webhookmodels.StripeInvoice) error {
	// if !IsLineCountAllowed(req.Lines.Count) {
	// 	return nil
	// }

	// item := req.Lines.Data[len(req.Lines.Data)-1]

	// // stripe sends 'subscription' object in line item for 1st
	// // subscription 'invoiceitem' object if it's change in plans
	// id := item.SubscriptionId
	// if id == "" {
	// 	id = item.Id
	// }

	// subscription := paymentmodels.NewSubscription()
	// if err := subscription.ByProviderId(id, ProviderName); err != nil {
	// 	return err
	// }

	// plan := paymentmodels.NewPlan()
	// if err := plan.ByProviderId(item.Plan.ID, ProviderName); err != nil {
	// 	return err
	// }

	// if subscription.PlanId != plan.Id {
	// 	Log.Info(
	// 		"'invoice.created': subscription: %v has planId: %v, but 'invoiced.created' webhook has planId: %v.",
	// 		subscription.Id, subscription.PlanId, plan.Id,
	// 	)
	// }

	// Log.Info(
	// 	"'invoice.created': Updating subscription: %v to planId: %v, starting: %v",
	// 	subscription.Id, plan.Id, time.Unix(int64(item.Period.Start), 0),
	// )

	// err := subscription.UpdateInvoiceCreated(
	// 	plan.AmountInCents, plan.Id,
	// 	int64(item.Period.Start), int64(item.Period.End),
	// )

	// if err != nil {
	// 	Log.Error("'invoice.created': updating invoice created failed: %v", err)
	// }

	return nil
}

//----------------------------------------------------------
// CustomerDeleted
//----------------------------------------------------------

func CustomerDeletedWebhook(req *webhookmodels.StripeCustomer) error {
	return nil

	// customer := paymentmodels.NewCustomer()
	// if err := customer.ByProviderCustomerId(req.ID); err != nil {
	// 	return err
	// }

	// return customer.DeleteSubscriptionsAndItself()
}
