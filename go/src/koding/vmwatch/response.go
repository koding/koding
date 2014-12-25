package main

import "fmt"

type Response struct {
	CanStart                   bool
	Reason                     string
	CurrentUsage, AllowedUsage float64
}

func checker(username string) Response {
	for _, metric := range metricsToSave {
		resp := metric.IsUserOverLimit(username)

		if resp.OverLimit {
			return Response{
				CanStart:     false,
				AllowedUsage: resp.AllowedUsage,
				CurrentUsage: resp.CurrentUsage,
				Reason:       fmt.Sprintf("%s over limit", metric.GetName()),
			}
		}
	}

	return Response{CanStart: true}
}
