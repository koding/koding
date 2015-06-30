package main

import (
	"fmt"
	"koding/kites/kloud/pkg/dnsclient"
	"log"
)

type TestDomains struct {
	DNS *dnsclient.Route53
}

func (t *TestDomains) Process() {
	fmt.Println("Processing TestDomains")

	records, err := t.DNS.GetAll("")
	if err != nil {
		log.Println(err)
		return
	}

	for _, record := range records {
		fmt.Printf("%+v\n", record.Name)
	}
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
