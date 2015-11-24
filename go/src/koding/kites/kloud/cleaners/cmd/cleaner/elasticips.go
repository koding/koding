package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
)

type ElasticIPs struct {
	Lookup *lookup.Lookup

	nonused *lookup.Addresses
	err     error
}

func (e *ElasticIPs) Process() {
	addressess := e.Lookup.FetchIpAddresses()

	e.nonused = addressess.NotAssociated()
}

func (e *ElasticIPs) Run() {
	e.nonused.ReleaseAll()
}

func (e *ElasticIPs) Result() string {
	if e.err != nil {
		return fmt.Sprintf("elasticIPs: error '%s'", e.err.Error())
	}

	return fmt.Sprintf("Released(removed) %d non associated elastic IP addresses",
		e.nonused.Count())
}

func (e *ElasticIPs) Info() *taskInfo {
	return &taskInfo{
		Title: "ElasticIPs",
		Desc:  "Release(delete) elasticIPs which are not associated to any instance",
	}
}
