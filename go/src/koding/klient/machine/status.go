package machine

import (
	"strings"
	"time"
)

// State represents our understanding of machine state. Whether or not we can
// communicate with it, etc.
type State int

const (
	// StateUnknown is a zero value and represents unknown state.
	StateUnknown State = iota

	// StateOffline describes machine that is not reachable by host client.
	StateOffline

	// StateOnline describes machine that is reachable for client's pinger.
	StateOnline

	// StateConnected indicates that there is an active machine connection.
	StateConnected
)

// String implements fmt.Stringer interface and is used for pretty-printing
// machine state.
func (s State) String() string {
	switch s {
	case StateUnknown:
		return "<unknown>"
	case StateOffline:
		return "offline"
	case StateOnline:
		return "online"
	case StateConnected:
		return "connected"
	default:
		return "<unknown>"
	}
}

// Status represents the current status of machine.
type Status struct {
	// State stores the current machine state.
	State State `json:"state"`

	// Reason is a short message that describes why machine is in current state.
	Reason string `json:"reason"`

	// Since indicates when the state was set.
	Since time.Time `json:"since"`
}

// String implements fmt.Stringer interface and prints Status structure in
// more human readable form.
func (s *Status) String() string {
	toks := []string{
		"status: " + s.State.String(),
	}

	if s.Reason != "" {
		toks = append(toks, "reason: "+s.Reason)
	}

	if s.Since.IsZero() {
		toks = append(toks, "since: <unknown>")
	} else {
		toks = append(toks, "since: "+s.Since.Format(time.RFC822))
	}

	return strings.Join(toks, ", ")
}

// MergeStatus is an utility function that merges two statuses into one. Younger
// statuses have higher priority. But, if both have identical state, older
// status may be returned as we assume that it didn't change at all.
func MergeStatus(a, b Status) Status {
	// Swap a with b when b is older than a.
	if a.Since.After(b.Since) {
		b, a = a, b
	}

	// Handle zero values.
	if a.State == 0 && a.Reason == "" && a.Since.IsZero() {
		return b
	}

	if a.State != b.State {
		return b
	}

	if b.Reason == "" {
		return a
	}

	// Copy time from older status when state did not change.
	b.Since = a.Since
	return b
}
