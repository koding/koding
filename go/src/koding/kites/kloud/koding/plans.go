package koding

type Plan interface {
	// Total checks whether the given plan has a reached the total machine
	// limit
	Total() error

	// Storage checks whether the given plan has sufficent storage
	Storage() error

	// Timeout checks whether the given plan has reached the inactiviy timeout
	Timeout() error

	// AlwaysOn() returns true if the user is able to have AlwaysOn() plans
	AlwaysOn() (bool, error)
}

// Plan defines a single koding plan
type PlanName int

const (
	// Unknown is a plan that needs to be resolved manually
	Unknown PlanName = iota

	// Free:  1 VM, 0 Always On, 30 min timeout -- CAN ONLY CREATE ONE t2.micro (1GB
	// RAM, 3GB Storage)
	Free

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

func (p PlanName) String() string {
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
