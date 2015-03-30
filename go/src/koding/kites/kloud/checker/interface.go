package checker

import "koding/kites/kloud/provider/koding"

type Payment struct {
	Plan  koding.Plan
	State string
}

// Checker checks various aspects of a machine. It is used for limiting certain
// aspects of a machine, such as the total allowed machine count, storage size
// and etc.
type Checker interface {
	// Total checks whether the user has reached the current plan's limit of
	// having a total number numbers of machines. It returns an error if the
	// limit is reached or an unexplained error happaned.
	Total(p *Payment) error

	// AlwaysOn checks whether the given machine has reached the current plans
	// always on limit
	AlwaysOn(p *Payment) error

	// SnapshotTotal checks whether the user reached the current plan's limit
	// of having a total numbers of snapshots. It returns an error if the limit
	// is reached or an unexplained error happened
	SnapshotTotal(p *Payment) error

	// Storage checks whether the user has reached the current plan's limit
	// total storage with the supplied wantStorage information. It returns an
	// error if the limit is reached or an unexplained error happaned.
	Storage(p *Payment, wantStorage int) error

	// AllowedInstances checks whether the given machine has the permisison to
	// create the given instance type
	AllowedInstances(p *Payment, wantInstance string) error

	// NetworkUsage checks whether the given machine has exceeded the network
	// outbound limit
	NetworkUsage(p *Payment) error

	// PlanState checks whether the given plan is valid or expired
	PlanState(p *Payment) error
}
