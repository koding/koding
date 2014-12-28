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

func checker(username string) Response {
	for _, metric := range metricsToSave {
		yes, err := exemptFromStopping(metric.GetName(), username)
		if err != nil {
			log.Println(err)
			return Response{CanStart: true}
		}

		if yes {
			return Response{CanStart: true}
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
