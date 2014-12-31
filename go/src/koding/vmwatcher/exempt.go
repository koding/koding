package main

var ExemptUsers = []interface{}{
	"sent-hil",
}

// checks if user is exempt from metric checkers, if something goes
// wrong while checking, we return true as a precaution
func exemptFromStopping(metricName, username string) (bool, error) {
	isExempt, err := storage.ExemptGet(metricName, username)
	if err != nil {
		return true, err
	}

	if isExempt {
		return true, nil
	}

	return false, nil
}
