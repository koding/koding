package main

import "koding/kites/kloud/cleaners/lookup"

type UnVerified struct {
	Instances *lookup.MultiInstances
	Machines  map[string]lookup.MachineDocument
	Cleaner   *Cleaner

	stopData map[string]*StopData
}

func (u *UnVerified) Process() {
}

func (u *UnVerified) Run() {
}

func (u *UnVerified) Result() string {
	return ""
}

func (u *UnVerified) Info() *taskInfo {
	return &taskInfo{
		Title: "UnVerified",
		Desc:  "Turn off VMs of unverified accounts",
	}
}
