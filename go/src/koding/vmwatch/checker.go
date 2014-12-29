package main

import "log"

type LimitResponse struct {
	CanStart                   bool
	CurrentUsage, AllowedUsage float64
	Reason                     string
}

// iterate through each metric, check if user is over limit for that
// metric, return true if yes, go onto next metric if not
func checker(username string) *LimitResponse {
	for _, metric := range metricsToSave {
		lr, err := metric.IsUserOverLimit(username)
		if err != nil {
			log.Println(err)
			return &LimitResponse{CanStart: true}
		}

		if !lr.CanStart {
			return lr
		}
	}

	return &LimitResponse{CanStart: true}
}
