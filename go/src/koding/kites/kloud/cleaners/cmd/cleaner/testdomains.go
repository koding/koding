package main

import "fmt"

type TestDomains struct {
}

func (t *TestDomains) Process() {
	fmt.Println("Processing TestDomains")
}

func (t *TestDomains) Run() {
	fmt.Println("Running TestDomains")
}

func (t *TestDomains) Result() string {
	return ""
}

func (t *TestDomains) Info() *taskInfo {
	return &taskInfo{
		Title: "TestDomains",
		Desc:  "Delete domains belonging to development and sandbox environment.",
	}
}
