package main

import (
	"fmt"
	"koding/kites/kloud/pkg/dnsclient"
)

type TestDomains struct {
	DNS     *dnsclient.Route53
	records map[string]*dnsclient.Record
	err     error
}

func (t *TestDomains) Process() {
	fmt.Println("Processing TestDomains")

	prevRecord := ""
	lastRecord := ""
	t.records = make(map[string]*dnsclient.Record, 0)

	for {
		records, err := t.DNS.GetAll(lastRecord)
		if err != nil {
			t.err = err
			return
		}

		lastRecord = records[len(records)-1].Name
		if lastRecord == prevRecord {
			break
		}

		// do not include the first record, because it's alread included in the
		// previous round
		for _, record := range records[1:] {
			// do not add NS records
			if record.Name == "dev.koding.io." {
				continue
			}

			t.records[record.Name] = record
		}
	}
}

func (t *TestDomains) Run() {
	if len(t.records) == 0 {
		return
	}

	fmt.Println("Removing '%d' test domains", len(t.records))
}

func (t *TestDomains) Result() string {
	if t.err != nil {
		return fmt.Sprintf("testDomains: error '%s'", t.err.Error())
	}

	return fmt.Sprintf("removed '%d' development domains from dev.koding.io hosted zone",
		len(t.records))
}

func (t *TestDomains) Info() *taskInfo {
	return &taskInfo{
		Title: "TestDomains",
		Desc:  "Delete domains belonging to development and sandbox environment.",
	}
}
