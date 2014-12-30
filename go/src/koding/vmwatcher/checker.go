package main

import "log"

type LimitResponse struct {
	CanStart     bool    `json:"can_start"`
	CurrentUsage float64 `json:"current_usage"`
	AllowedUsage float64 `json:"allowed_usage"`
	Reason       string  `json:"reason"`
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
