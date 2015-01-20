package main

var ExemptUsers = []interface{}{
	"sent-hil",
}

// saves exempt users for each metric
func saveExemptUsers() {
	for _, metric := range metricsToSave {
		err := storage.Save(metric.GetName(), ExemptKey, ExemptUsers)
		if err != nil {
			Log.Fatal(err.Error())
		}
	}

	Log.Debug("Saved: %v users as exempt", len(ExemptUsers))
}

// checks if user is exempt from metric checkers, if something goes
// wrong while checking, we return true as a precaution
func exemptFromStopping(metricName, username string) (bool, error) {
	isExempt, err := storage.Exists(metricName, ExemptKey, username)
	if err != nil && !isRedisRecordNil(err) {
		return true, nil
	}

	if isExempt {
		return true, nil
	}

	return false, nil
}
