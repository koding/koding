package repair

import (
	"fmt"
	"time"
)

// RetryRepair wraps a normal Repairer with retry logic, allowing normal
// repairers to simply fail as needed and not implement retry logic. The number
// of attempts and
type RetryRepair struct {
	// The internal repairier to wrap.
	Repairer

	// The options that this repairer will use.
	Options RetryOptions
}

// RetryOptions contains the configuration for a RetryRepair instance.
type RetryOptions struct {
	// The max number of retries for Status() failures. Note that this represents
	// a *retry*, so a value of zero still means 1 total attempts, and no retries.
	StatusRetries uint

	// The length of time between each status retries. Does not pause on the
	// first attempt.
	StatusDelay time.Duration

	// The max number of retries for Repair() failures. Note that this represents
	// a *retry*, so a value of zero still means 1 total attempts, and no retries.
	RepairRetries uint

	// The length of time between each repair retries. Does not pause on the
	// first attempt.
	RepairDelay time.Duration
}

// NewRetryRepair creates a new RetryRepair instance.
func NewRetryRepair(r Repairer, opts RetryOptions) *RetryRepair {
	return &RetryRepair{
		Repairer: r,
		Options:  opts,
	}
}

// String returns the RetryRepair's name, along with the underlying repairer.
func (r *RetryRepair) String() string {
	return fmt.Sprintf("retryrepair:%s", r.Repairer.String())
}

// Status returns the eventual (after any given retries needed) status of the
// Repairer. A failure will only be returned if the number of retries
// exceeds Options.StatusRetries.
func (r *RetryRepair) Status() (bool, error) {
	var (
		ok  bool
		err error
	)

	// The <= check is to ensure we always run once, *plus* the number of retries
	// specified.
	for i := uint(0); i <= r.Options.StatusRetries; i++ {
		ok, err = r.Repairer.Status()
		if ok {
			break
		}

		if r.Options.RepairDelay > 0 {
			time.Sleep(r.Options.RepairDelay)
		}
	}

	return ok, err
}

// Repair returns the eventual (after any given retries needed) repair result
// of the Repairer. A failure will only be returned if the number of retries
// exceeds Options.RepairRetries.
func (r *RetryRepair) Repair() error {
	var err error

	// The <= check is to ensure we always run once, *plus* the number of retries
	// specified.
	for i := uint(0); i <= r.Options.RepairRetries; i++ {
		if err = r.Repairer.Repair(); err == nil {
			break
		}

		if r.Options.RepairDelay > 0 {
			time.Sleep(r.Options.RepairDelay)
		}
	}

	return err
}
