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

type Limits struct {
	Total     int
	Storage   int
	Timeout   time.Duration
	AlwaysOn  int
	Instances map[InstanceType]struct{}
}

// Plan defines a single koding plan
type Plan int

const (
	// Free:  1 VM, 0 Always On, 30 min timeout -- CAN ONLY CREATE ONE t2.micro (1GB
	// RAM, 3GB Storage)
	Free Plan = iota + 1

	// Hobbyist: 3 VMs, 0 Always On, 6 hour timeout -- t2.micros ONLY (1GB RAM,
	// 3GB Storage)
	Hobbyist

	// Developer: 3 VMs, 1 Always On, 3GB total RAM, 20GB total Storage, 12
	// hour timeout  -- t2.micro OR t2.small  (variable Storage)
	Developer

	// Professional: 5 VMs, 2 Always On, 5GB total RAM, 50GB total Storage, 12
	// hour timeout  -- t2.micro OR t2.small OR t2.medium  (variable Storage)
	Professional

	// Super: 10 VMs, 5 Always On, 10GB total RAM, 100GB total Storage, 12 hour
	// timeout  -- t2.micro OR t2.small OR t2.medium  (variable Storage)
	Super
)

var plans = map[Plan]Limits{
	Free: {
		Total:    1,
		Storage:  3,
		Timeout:  30 * time.Minute,
		AlwaysOn: 0,
		Instances: map[InstanceType]struct{}{
			T2Micro: {},
		},
	},
	Hobbyist: {
		Total:    3,
		Storage:  3,
		Timeout:  6 * time.Hour,
		AlwaysOn: 0,
		Instances: map[InstanceType]struct{}{
			T2Micro: {},
		},
	},
	Developer: {
		Total:    3,
		Storage:  20,
		Timeout:  12 * time.Hour,
		AlwaysOn: 1,
		Instances: map[InstanceType]struct{}{
			T2Micro: {},
			T2Small: {},
		},
	},
	Professional: {
		Total:    5,
		Storage:  50,
		Timeout:  12 * time.Hour,
		AlwaysOn: 2,
		Instances: map[InstanceType]struct{}{
			T2Micro:  {},
			T2Small:  {},
			T2Medium: {},
		},
	},
	Super: {
		Total:    10,
		Storage:  100,
		Timeout:  12 * time.Hour,
		AlwaysOn: 5,
		Instances: map[InstanceType]struct{}{
			T2Micro:  {},
			T2Small:  {},
			T2Medium: {},
		},
	},
}

func (p Plan) Limits() Limits {
	return plans[p]
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
	default:
		return "Unknown"
	}
}
