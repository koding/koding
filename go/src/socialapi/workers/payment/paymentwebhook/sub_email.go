package main

func subscriptionEmail(customerId, planName string, action Action) error {
	user, err := getUserForCustomer(customerId)
	if err != nil {
		return err
	}

	opts := map[string]string{"planName": planName}

	Log.Info("Sent subscription email to: %s with plan: %s", user.Email,
		planName)

	return Email(user, action, opts)
}
