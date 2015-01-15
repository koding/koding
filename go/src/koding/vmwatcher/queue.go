package main

func queueUsernamesForMetricGet() error {
	machines, err := getRunningVms()
	if err != nil {
		return err
	}

	if len(machines) == 0 {
		return nil
	}

	usernames := []interface{}{}
	for _, machine := range machines {
		usernames = append(usernames, machine.Credential)
	}

	for _, metric := range metricsToSave {
		err := queue(metric.GetName(), GetQueueKey, usernames)
		if err != nil {
			Log.Error(err.Error())
			continue
		}

	}

	return nil
}

func queueOverlimitUsers() {
	for _, metric := range metricsToSave {
		for limitName, _ := range limitsToAction {
			machines, err := metric.GetMachinesOverLimit(limitName)
			if err != nil {
				Log.Error(err.Error())
				continue
			}

			usernames := extractUsernames(machines)
			err = storage.Save(metric.GetName(), StopQueueKey, usernames)
			if err != nil {
				Log.Error(err.Error())
				continue
			}
		}
	}
}

func queue(key, subkey string, members []interface{}) error {
	err := storage.Save(key, subkey, members)
	if err == nil {
		Log.Debug("Queued: %d members for metric: %s#%s", len(members), key, subkey)
	}

	return nil
}
