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
		response, err := metric.IsUserOverLimit(username)
		if err != nil {
			log.Println(err)
			continue
		}

		if !response.CanStart {
			return response
		}
	}

	return &LimitResponse{CanStart: true}
}
