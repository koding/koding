package machine

import (
	"fmt"
	"math"
	"time"

	"koding/klient/machine"
)

// Info stores the basic information about the machine.
type Info struct {
	// ID is an unique identifier for a given machine.
	ID string `json:"id"`

	// Alias stores a human readable alias for machine.
	Alias string `json:"alias"`

	// Team is the name of the team which created the machine.
	Team string `json:"team"`

	// Stack describes machine parent stack.
	Stack string `json:"stack"`

	// Provider represents machine provider.
	Provider string `json:"provider"`

	// Label is the machine label, as seen by the Koding UI.
	Label string `json:"label"`

	// The IP of the running machine.
	IP string `json:"ip"`

	// QueryString is string representation of kite protocol query.
	QueryString string `json:"queryString"`

	// HTTP address to remote machine kite.
	RegisterURL string `json:"registerUrl"`

	// CreatedAt tells about machine age.
	CreatedAt time.Time `json:"createdAt"`

	// The machines last known status.
	Status machine.Status `json:"status"`

	// The user name of the Koding user.
	Username string `json:"username"`

	// Owner describes who shared the machine if it's shared.
	Owner string `json:"owner"`
}

// InfoSlice attaches the methods of Interface to []Info, they provide priority
// based sorting and finding methods.
type InfoSlice []*Info

func (s InfoSlice) Len() int {
	return len(s)
}

func (s InfoSlice) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}

// Less defines the a group of machine Info structures as a logical collection,
// such as online machines, mounted machines, etc.
func (s InfoSlice) Less(i, j int) bool {
	switch {
	case groupRank(s[i]) < groupRank(s[j]):
		return true
	case groupRank(s[i]) == groupRank(s[j]):
		return s[i].Alias < s[j].Alias
	default:
		return false
	}
}

func groupRank(i *Info) int {
	if i == nil {
		return -1
	}

	switch {
	case i.Status.State == machine.StateConnected: // There is an active connection.
		return 0
	case i.Status.State == machine.StateOnline: // On-line machines.
		return 1
	case i.Status.State == machine.StateOffline: // Off-line machines.
		return 2
	default:
		return 3
	}
}

// PrettyStatus prints machine status in short and more human friendly format.
func PrettyStatus(status machine.Status, now time.Time) string {
	if status.State == machine.StateOnline {
		return fmt.Sprintf("%s (%s)", status.State, ShortDuration(status.Since, now))
	}

	timeReasonFmt := ShortDuration(status.Since, now)
	if status.Reason != "" {
		timeReasonFmt += ": " + status.Reason
	}

	return fmt.Sprintf("%s (%s)", status.State, timeReasonFmt)
}

// ShortDuration prints time.Duration between tow time points in very short
// format.
func ShortDuration(t, now time.Time) string {
	dur := now.Sub(t)

	if dur.Seconds() < 60.0 {
		return fmt.Sprintf("%ds", int64(dur.Seconds()))
	}

	if dur.Minutes() < 60.0 {
		secs := math.Mod(dur.Seconds(), 60)
		return fmt.Sprintf("%dm %ds", int64(dur.Minutes()), int64(secs))
	}

	if dur.Hours() < 24.0 {
		mins := math.Mod(dur.Minutes(), 60)
		return fmt.Sprintf("%dh %dm", int64(dur.Hours()), int64(mins))
	}

	hours := math.Mod(dur.Hours(), 24)
	return fmt.Sprintf("%dd %dh", int64(dur.Hours()/24), int64(hours))
}
