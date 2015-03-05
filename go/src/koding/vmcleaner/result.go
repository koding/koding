package main

import "fmt"

type Result struct {
	Successful, Failure int
	Warning             string
}

func (r *Result) String() string {
	return fmt.Sprintf("Ran for WARNING: %v, successful: %v, failed: %v",
		r.Warning, r.Successful, r.Failure)
}
