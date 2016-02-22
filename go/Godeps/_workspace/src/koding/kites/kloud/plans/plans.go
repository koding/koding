package plans

import (
	"koding/db/mongodb"
	"koding/kites/kloud/api/amazon"
	"time"

	"github.com/koding/logging"
)

// Plan defines a single koding plan. All Koding plans should have:
// 1. 50 min timeout for non-always on vms
// 2. only t2.micro's as vm type
type Plan struct {
	// Name defines the plan name
	Name string

	// TotalLimit defines the total limit of machines a plan can have
	TotalLimit int

	// alwaysOnLimit defines the total limit of machines that can be always on.
	// These machines are not subject to the Timeout mechanism and are never
	// shut down
	AlwaysOnLimit int

	// storageLimit defines the total storage a plan can have. A user might split
	// this storage into three instances if the totalLimit limit is three. An example:
	// User has a 25GB storage plan and a totalLimit limit of 3 machines. He/she can use:
	// 10GB for the first machine
	// 10GB for the second machine
	// 5GB for the third machine
	StorageLimit int

	// Timeout defines the timeout in which a machine is shutdown after an
	// inactivity. alwaysOnLimit vm's are not subject to this limitation
	Timeout time.Duration

	// SnapshotTotal defines the totalLimit limit of snapshots a machine can have
	SnapshotTotalLimit int

	// allowedInstances defines the instance types a plan can have when building a
	// machine.
	allowedInstances map[InstanceType]struct{}

	DB        *mongodb.MongoDB
	Log       logging.Logger
	AWSClient *amazon.Amazon

	// environment defines the environment in which the users are working, such
	// as Production, Development, sandbox et.. It's usually based on
	// c.Kite.Config.Environment
	Environment string

	networkUsageEndpoint string
}

var Plans = map[string]*Plan{
	"free":         Free,
	"hobbyist":     Hobbyist,
	"developer":    Developer,
	"professional": Professional,
	"super":        Super,
	"koding":       Koding,
	"betatester":   Betatester,
}

// For any plan changes, please update the following files:
//
// - /workers/social/lib/social/models/computeproviders/plans.coffee
var (
	// Free: 1 VM, 0 Always On, 3GB total storage
	Free = &Plan{
		Name:               "Free",
		TotalLimit:         1,
		SnapshotTotalLimit: 0,
		AlwaysOnLimit:      0,
		StorageLimit:       3,
		Timeout:            50 * time.Minute,
		allowedInstances: map[InstanceType]struct{}{
			T2Nano:  {},
			T2Micro: {}, // users of old free plans should be allowed to rebuild their instances
		},
	}

	// Hobbyist: 1 VM, 1 Always On, 10GB total storage
	Hobbyist = &Plan{
		Name:               "Hobbyist",
		TotalLimit:         1,
		SnapshotTotalLimit: 1,
		AlwaysOnLimit:      1,
		StorageLimit:       10,
		Timeout:            50 * time.Minute,
		allowedInstances: map[InstanceType]struct{}{
			T2Nano:  {},
			T2Micro: {},
		},
	}

	// Developer: 3 VMs, 1 Always On,  25GB total storage
	Developer = &Plan{
		Name:               "Developer",
		TotalLimit:         3,
		SnapshotTotalLimit: 3,
		AlwaysOnLimit:      1,
		StorageLimit:       25,
		Timeout:            50 * time.Minute,
		allowedInstances: map[InstanceType]struct{}{
			T2Nano:  {},
			T2Micro: {},
		},
	}

	// Professional: 5 VMs, 2 Always On, 50GB total storageLimit
	Professional = &Plan{
		Name:               "Professional",
		TotalLimit:         5,
		SnapshotTotalLimit: 5,
		AlwaysOnLimit:      2,
		StorageLimit:       50,
		Timeout:            50 * time.Minute,
		allowedInstances: map[InstanceType]struct{}{
			T2Nano:  {},
			T2Micro: {},
		},
	}

	// Super: 10 VMs, 5 Always On, 100GB total storageLimit
	Super = &Plan{
		Name:               "Super",
		TotalLimit:         10,
		SnapshotTotalLimit: 10,
		AlwaysOnLimit:      5,
		StorageLimit:       100,
		Timeout:            50 * time.Minute,
		allowedInstances: map[InstanceType]struct{}{
			T2Nano:  {},
			T2Micro: {},
		},
	}

	// Koding: 100 VMs, 100 Always On, 1000GB total storageLimit
	// Internal use only
	Koding = &Plan{
		Name:               "Koding internal",
		TotalLimit:         20,
		SnapshotTotalLimit: 20,
		AlwaysOnLimit:      20,
		StorageLimit:       200,
		Timeout:            50 * time.Minute,
		allowedInstances: map[InstanceType]struct{}{
			T2Nano:   {},
			T2Micro:  {},
			T2Small:  {},
			T2Medium: {},
		},
	}

	// Betatester: 1 VM, 1 Always On, 3GB total storage
	Betatester = &Plan{
		Name:               "Betatest",
		TotalLimit:         1,
		SnapshotTotalLimit: 0,
		AlwaysOnLimit:      1,
		StorageLimit:       3,
		Timeout:            50 * time.Minute,
		allowedInstances: map[InstanceType]struct{}{
			T2Nano:  {},
			T2Micro: {},
		},
	}
)

func (p *Plan) String() string {
	return p.Name
}
