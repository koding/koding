package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"

	"github.com/mitchellh/goamz/ec2"
)

type ElasticIPs struct {
	Lookup *lookup.Lookup

	nonused map[string][]ec2.Address
	err     error
}

func (e *ElasticIPs) Process() {
	addressess := e.Lookup.FetchIpAddresses()

	e.nonused = make(map[string][]ec2.Address)

	for region, a := range addressess {
		nonAssociatedAddressess := make([]ec2.Address, 0)
		for _, address := range a {
			if address.AssociationId == "" {
				nonAssociatedAddressess = append(nonAssociatedAddressess, address)
			}
		}

		fmt.Printf("region '%s' has %d addresses (which %d are not associated) \n",
			region, len(a), len(nonAssociatedAddressess))
		e.nonused[region] = nonAssociatedAddressess
	}
}

func (e *ElasticIPs) Run() {

}

func (e *ElasticIPs) Result() string {
	if e.err != nil {
		return fmt.Sprintf("elasticIPs: error '%s'", e.err.Error())
	}

	return ""
}

func (e *ElasticIPs) Info() *taskInfo {
	return &taskInfo{
		Title: "ElasticIPs",
		Desc:  "Release(delete) elasticIPs which are not associated to any instance",
	}
}
