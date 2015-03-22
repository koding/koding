package koding

import (
	"time"
)

type Instance struct {
	CPU int
	Mem int
}

type InstanceType int

const (
	T2Micro InstanceType = iota + 1
	T2Small
	T2Medium
)

var instances = map[string]InstanceType{
	"t2.micro":  T2Micro,
	"t2.small":  T2Small,
	"t2.medium": T2Medium,
}

func (i InstanceType) String() string {
	switch i {
	case T2Micro:
		return "t2.micro"
	case T2Small:
		return "t2.small"
	case T2Medium:
		return "t2.medium"
	default:
		return "UnknownInstance"
	}
}

// http://aws.amazon.com/ec2/instance-types/
// Model		vCPU	Mem (GiB)
// t2.micro		1		1
// t2.small		1		2
// t2.medium	2		4
func (i InstanceType) Instance() Instance {
	switch i {
	case T2Micro:
		return Instance{CPU: 1, Mem: 1}
	case T2Small:
		return Instance{CPU: 1, Mem: 2}
	case T2Medium:
		return Instance{CPU: 2, Mem: 4}
	}

	return Instance{}
}

// Limits defines several independent limits that are applied to a Plan.
type Limits struct {
	// Total defines the total limit of machines a plan can have
	Total int

	// AlwaysOn defines the total limit of machines that can be always on.
	// These machines are not subject to the Timeout mechanism and are never
	// shut down
	AlwaysOn int

	// Storage defines the total storage a plan can have. A user might split
	// this storage into three instances if the Total limit is three. An example:
	// User has a 25GB storage plan and a Total limit of 3 machines. He/she can use:
	// 10GB for the first machine
	// 10GB for the second machine
	// 5GB for the third machine
	Storage int

	// Timeout defines the timeout in which a machine is shutdown after an
	// inactivity. AlwaysOn vm's are not subject to this limitation
	Timeout time.Duration

	// SnapshotTotal defines the Total limit of snapshots a machine can have
	SnapshotTotal int

	// AllowedInstances defines the instance types a plan can have when building a
	// machine.
	AllowedInstances map[InstanceType]struct{}
}

// Plan defines a single koding plan. All plans have:
// 1. 60 min timeout for non-always on vms
// 2. only t2.micro's as vm type
type Plan int

const (
	// Free: 1 VM, 0 Always On, 3GB total storage
	Free Plan = iota + 1

	// Hobbyist: 1 VM, 1 Always On, 10GB total storage
	Hobbyist

	// Developer: 3 VMs, 1 Always On,  25GB total storage
	Developer

	// Professional: 5 VMs, 2 Always On, 50GB total Storage
	Professional

	// Super: 10 VMs, 5 Always On, 100GB total Storage
	Super

	// Koding: 100 VMs, 100 Always On, 1000GB total Storage
	// Internal use only
	Koding

	// Betatester: 1 VM, 1 Always On, 3GB total storage
	Betatester
)

var plans = map[string]Plan{
	"free":         Free,
	"hobbyist":     Hobbyist,
	"developer":    Developer,
	"professional": Professional,
	"super":        Super,
	"koding":       Koding,
	"betatester":   Betatester,
}

var planLimits = map[Plan]Limits{
	Free: {
		Total:         1,
		SnapshotTotal: 0,
		AlwaysOn:      0,
		Storage:       3,
		Timeout:       60 * time.Minute,
		AllowedInstances: map[InstanceType]struct{}{
			T2Micro: {},
		},
	},
	Hobbyist: {
		Total:         1,
		SnapshotTotal: 1,
		AlwaysOn:      1,
		Storage:       10,
		Timeout:       60 * time.Minute,
		AllowedInstances: map[InstanceType]struct{}{
			T2Micro: {},
		},
	},
	Developer: {
		Total:         3,
		SnapshotTotal: 3,
		AlwaysOn:      1,
		Storage:       25,
		Timeout:       60 * time.Minute,
		AllowedInstances: map[InstanceType]struct{}{
			T2Micro: {},
		},
	},
	Professional: {
		Total:         5,
		SnapshotTotal: 5,
		AlwaysOn:      2,
		Storage:       50,
		Timeout:       60 * time.Minute,
		AllowedInstances: map[InstanceType]struct{}{
			T2Micro: {},
		},
	},
	Super: {
		Total:         10,
		SnapshotTotal: 10,
		AlwaysOn:      5,
		Storage:       100,
		Timeout:       60 * time.Minute,
		AllowedInstances: map[InstanceType]struct{}{
			T2Micro: {},
		},
	},
	Koding: {
		Total:         20,
		SnapshotTotal: 20,
		AlwaysOn:      20,
		Storage:       200,
		Timeout:       60 * time.Minute,
		AllowedInstances: map[InstanceType]struct{}{
			T2Micro: {}, T2Small: {}, T2Medium: {},
		},
	},
	Betatester: {
		Total:         1,
		SnapshotTotal: 0,
		AlwaysOn:      1,
		Storage:       3,
		Timeout:       60 * time.Minute,
		AllowedInstances: map[InstanceType]struct{}{
			T2Micro: {},
		},
	},
}

func (p Plan) Limits() Limits {
	return planLimits[p]
}

func (p Plan) String() string {
	switch p {
	case Free:
		return "Free"
	case Hobbyist:
		return "Hobbyist"
	case Developer:
		return "Developer"
	case Professional:
		return "Professional"
	case Super:
		return "Super"
	case Koding:
		return "Koding"
	case Betatester:
		return "Betatester"
	default:
		return "Unknown"
	}
}
