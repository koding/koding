package main

var ExemptUsers = []interface{}{
	"sent-hil",
}

func exemptFromStopping(metricName, username string) (bool, error) {
	plan, err := getPlanForUser(username)
	if err != nil {
		return false, err
	}

	if plan != "free" {
		return true, nil
	}

	isExempt, err := storage.ExemptGet(metricName, username)
	if err != nil {
		return false, err
	}

	if isExempt {
		return true, nil
	}

	return false, nil
}

func getPlanForUser(username string) (string, error) {
	return "", nil
}
