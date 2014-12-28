package main

import (
	"fmt"
	"log"
)

type Response struct {
	CanStart                   bool
	Reason                     string
	CurrentUsage, AllowedUsage float64
}

// iterate through each metric, check if user is exempt for that metric,
// if exempt, check next metric, since an user can be exempt for one
// metric, but not exempt for other one; if not exempt check if overlimit.
func checker(username string) Response {
	for _, metric := range metricsToSave {
		yes, err := exemptFromStopping(metric.GetName(), username)
		if err != nil {
			log.Println(err)
			return Response{CanStart: true}
		}

		if yes {
			continue
		}

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
