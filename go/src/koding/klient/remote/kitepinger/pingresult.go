package kitepinger

import "time"

// ChangeSummary represents information about a change in pinging state, Success
// or Failure. It contains the time the change happened, how long the old state
// existed for, and what the new state is.
//
// For example, if the KingPinger has been successfully pinging for 10 minutes and
// just now failed to ping, ChangeSummary will look like this:
//
//    ChangeSummary{
//      NewStatus:      Status.Failure,
//      NewStatusTime:  time.Now(),
//      OldStatus:      Status.Success,
//      OldStatusDur:   time.Minute*10,
//    }
//
type ChangeSummary struct {
	// The new/current status.
	NewStatus Status

	// The time that the NewStatus occurred. Ie, when a Failed ping first occurred.
	NewStatusTime time.Time

	// The previous status.
	OldStatus Status

	// The length of time that previous status existed for.
	OldStatusDur time.Duration
}

// CurrentSummary is similar to ChangeSummary, except that it represents the
// current state at the time of the object's creation.
type CurrentSummary struct {
	// The state of the KitePingers ping attempts
	Status Status

	// The duration that the current status has been occurring for.
	StatusDur time.Duration
}

// Status represents a Pinging status, either Success or Failure.
type Status int

const (
	// Unknown is the zero value of a Status.
	Unknown Status = iota

	// Success is the ping(s) succeeded.
	Success

	// Failure is the ping(s) failed.
	Failure
)

// String implements stringer for kitepinger.Status
func (s Status) String() string {
	switch s {
	case Success:
		return "Success"
	case Failure:
		return "Failure"
	default:
		return "Unknown Status"
	}
}
