package usage

import (
	"fmt"
	"time"

	"github.com/koding/kite"
)

// Plan defines the environment on which klient is going to act and work. A
// plan has limitations. Those limitiations are different for different plan
// kinds.
type Plan struct {
	// name is the plan name, "free", "micro", etc...
	name string

	// timeout defines the limit in which a machine can be RUNNING at most.
	// After the timeout is being reached, the machine is closed immediately.
	timeout time.Duration
}

type Usage struct {
	// plan stores a reference to the current plan
	plan *Plan `json:"-"`

	// latestActivity stores the time in which the latest activity was done.
	LatestActivity time.Time `json:"latest_activity"`

	// methodcalls stores the number of method calls
	MethodCalls int32 `json:"method_calls"`
}

func NewUsage() *Usage {
	return &Usage{
		// start with free, can be upgraded, downgraded later
		plan: &Plan{
			name:    "free",
			timeout: time.Minute * 30,
		},
		LatestActivity: time.Now(),
	}
}

// Counter resets the current usage and counts the incoming calls.
func (u *Usage) Counter(r *kite.Request) (interface{}, error) {

	fmt.Println("got a request for method: ", r.Method)
	// reset the latest activity
	u.LatestActivity = time.Now()

	// incrase the method calls
	u.MethodCalls += 1
	return nil, nil
}

// Current returns the current acvitiy usage
func (u *Usage) Current(r *kite.Request) (interface{}, error) {
	return u, nil
}
