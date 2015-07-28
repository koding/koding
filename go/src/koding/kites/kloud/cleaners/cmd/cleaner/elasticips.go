package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
)

type ElasticIPs struct {
	Lookup *lookup.Lookup
}

func (i *ElasticIPs) Process() {
	addressess := i.Lookup.FetchIpAddresses()

	for region, a := range addressess {
		fmt.Printf("%s has total %d addressess\n", region, len(a))
	}
}

func (i *ElasticIPs) Run() {
}

func (i *ElasticIPs) Result() string {
	return ""
}

func (i *ElasticIPs) Info() *taskInfo {
	return nil
}
