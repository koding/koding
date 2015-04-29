package main

import (
	"fmt"
	"time"

	"github.com/kr/pretty"
)

type strToInf map[string]interface{}

type UserResult struct {
	Level         int
	Username      string
	ExemptReson   string
	LastLoginDate string
}

func NewUserResults() []*UserResult {
	return []*UserResult{}
}

type Result struct {
	Desc       string
	Successful []*UserResult
	Failure    []*UserResult
	Exempt     []*UserResult
	StartedAt  string
	EndedAt    string
}

func NewResult(desc string) *Result {
	return &Result{
		Desc:       desc,
		Successful: NewUserResults(),
		Failure:    NewUserResults(),
		Exempt:     NewUserResults(),
		StartedAt:  time.Now().String(),
	}
}

func (r *Result) String() string {
	pretty.Println(r)

	return fmt.Sprintf(
		"Started: %v, Ran %v. Success: %v, Exempt: %v Ended: %v",
		r.StartedAt, r.Desc, len(r.Successful), len(r.Exempt), r.EndedAt,
	)
}
