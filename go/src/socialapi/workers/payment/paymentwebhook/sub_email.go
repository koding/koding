package main

func subscriptionEmail(customerId, planName string, action Action) error {
	user, err := getUserForCustomer(customerId)
	if err != nil {
		return err
	}

	opts := map[string]interface{}{"planName": planName}

	Log.Info("Sent subscription email to: %s with plan: %s", user.Email,
		planName)

	return SendEmail(user, action, opts)
}
