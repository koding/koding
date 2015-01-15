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
		err := storage.Save(metric.GetName(), GetQueueKey, usernames)
		if err != nil {
			Log.Error(err.Error())
			continue
		}

		Log.Debug("Queued: %d usernames for metric: %s", len(usernames), metric.GetName())
	}

	return nil
}
