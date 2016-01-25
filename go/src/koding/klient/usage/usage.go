package usage

import (
	"time"

	"github.com/koding/kite"
)

var MethodName = "klient.usage"

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
	latestActivity time.Time `json:"-"`

	// InactiveDuration reports the minimum duration since the latest activity.
	InactiveDuration time.Duration `json:"inactive_duration"`

	// Methodcalls stores the number of method calls
	MethodCalls int32 `json:"method_calls"`

	// CountedMethods
	countedMethods map[string]bool
}

func NewUsage(countedMethods map[string]bool) *Usage {
	return &Usage{
		// start with free, can be upgraded, downgraded later
		plan: &Plan{
			name:    "free",
			timeout: time.Minute * 30,
		},
		latestActivity: time.Now(),
		countedMethods: countedMethods,
	}
}

// Counter resets the current usage and counts the incoming calls.
func (u *Usage) Counter(r *kite.Request) (interface{}, error) {
	// don't reset for incoming methods that are not allowed
	if _, ok := u.countedMethods[r.Method]; !ok {
		return nil, nil
	}

	// reset the latest activity
	u.Reset()
	return nil, nil
}

// Reset resets all internal counters
func (u *Usage) Reset() {
	// reset the latest activity
	u.latestActivity = time.Now()
	u.InactiveDuration = 0
	u.MethodCalls += 1
}

// Current returns the current activity usage
func (u *Usage) Current(r *kite.Request) (interface{}, error) {
	u.Update()
	return u, nil
}

// Update updates all current metrics
func (u *Usage) Update() {
	// we do the calculation here to avoid time offsets on the remote side.
	// This is the most correct duration
	u.InactiveDuration = time.Since(u.latestActivity)
}
