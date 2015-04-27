package main

func subscriptionEmail(customerId, planName string, action Action) error {
	opts := map[string]interface{}{"planName": planName}
	return SendEmail(customerId, action, opts)
}
