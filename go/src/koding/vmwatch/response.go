package main

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
			}
		}
	}

	return Response{CanStart: true}
}
