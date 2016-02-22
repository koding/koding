package main

import (
	"fmt"
	"time"
)

type UserResult struct {
	Level         int
	Username      string
	ExemptReson   string
	LastLoginDate time.Time
}

func NewUserResults() []*UserResult {
	return []*UserResult{}
}

type Result struct {
	Desc       string
	Successful []*UserResult
	Failure    []*UserResult
	Exempt     []*UserResult
	StartedAt  time.Time
	EndedAt    string
}

func NewResult(desc string) *Result {
	return &Result{
		Desc:       desc,
		Successful: NewUserResults(),
		Failure:    NewUserResults(),
		Exempt:     NewUserResults(),
		StartedAt:  time.Now(),
	}
}

func (r *Result) String() string {
	return fmt.Sprintf(
		"Started: %s, Ran %v. Success: %v, Exempt: %v Ended: %v",
		r.StartedAt, r.Desc, len(r.Successful), len(r.Exempt), r.EndedAt,
	)
}
