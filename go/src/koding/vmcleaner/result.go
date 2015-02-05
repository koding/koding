package main

import "fmt"

type Result struct {
	Total, Successful, Failure int
	Warning                    int
}

func (r *Result) String() string {
	return fmt.Sprintf(
		"Ran for warning: %v total: %v, successful: %v, failed: %v",
		r.Warning, r.Total, r.Successful, r.Failure,
	)
}
