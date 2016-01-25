package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
)

type ElasticIPs struct {
	Lookup *lookup.Lookup

	nonused *lookup.Addresses
}

func (e *ElasticIPs) Process() {
	addressess := e.Lookup.FetchIpAddresses()

	e.nonused = addressess.NotAssociated()
}

func (e *ElasticIPs) Run() {
	e.nonused.ReleaseAll()
}

func (e *ElasticIPs) Result() string {
	return fmt.Sprintf("Released(removed) %d non associated elastic IP addresses",
		e.nonused.Count())
}

func (e *ElasticIPs) Info() *taskInfo {
	return &taskInfo{
		Title: "ElasticIPs",
		Desc:  "Release(delete) elasticIPs which are not associated to any instance",
	}
}

type DowngradedElasticIPs struct {
	Lookup  *lookup.Lookup
	Options *lookup.NotPaidOptions

	nonpaid *lookup.Addresses
}

func (e *DowngradedElasticIPs) Process() {
	addressess := e.Lookup.FetchIpAddresses()

	e.nonpaid = addressess.NotPaid(e.Options)
}

func (e *DowngradedElasticIPs) Run() {
	e.nonpaid.ReleaseAll()
}

func (e *DowngradedElasticIPs) Result() string {
	return fmt.Sprintf("Released (removed) %d non-paid elastic IP addresses",
		e.nonpaid.Count())
}

func (e *DowngradedElasticIPs) Info() *taskInfo {
	return &taskInfo{
		Title: "DowngradedElasticIPs",
		Desc:  "Release (delete) elasticIPs which are used by non-paying users",
	}
}
