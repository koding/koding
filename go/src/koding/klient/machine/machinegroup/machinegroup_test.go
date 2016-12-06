package machinegroup

import (
	"time"

	"koding/klient/machine"
)

// testOptions returns default Group options used for testing purposes.
func testOptions(b machine.ClientBuilder) *GroupOpts {
	return &GroupOpts{
		Builder:         b,
		DynAddrInterval: 10 * time.Millisecond,
		PingInterval:    50 * time.Millisecond,
	}
}
