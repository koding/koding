package machine

import (
	"fmt"
	"os"
	"sort"
	"time"

	"koding/kites/kloud/machine"
	"koding/kites/kloud/stack"
	"koding/klientctl/kloud"

	"github.com/koding/logging"
)

// ListOptions stores options for `machine list` call.
type ListOptions struct {
	Log logging.Logger
}

// List retrieves user's machines from kloud.
func List(options *ListOptions) ([]*Info, error) {
	kloud, err := kloud.Kloud()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error communicating with Koding:", err)
		return nil, err
	}

	req := &stack.MachineListRequest{}

	r, err := kloud.TellWithTimeout("machine.list", 10*time.Second, req)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error communicating with Koding:", err)
		return nil, err
	}

	res := &stack.MachineListResponse{}
	if err := r.Unmarshal(res); err != nil {
		return nil, err
	}

	infos := make([]*Info, len(res.Machines))
	for i, m := range res.Machines {
		infos[i] = &Info{
			Team:      m.Team,
			Stack:     m.Stack,
			Provider:  m.Provider,
			Label:     m.Label,
			IP:        m.IP,
			CreatedAt: m.CreatedAt,
			Status: Status{
				State:      fromMachineStateString(m.Status.State),
				Reason:     m.Status.Reason,
				ModifiedAt: m.Status.ModifiedAt,
			},
			Username: machineUserFromUsers(m.Users),
			Owner:    ownerFromUsers(m.Users),
		}
	}

	// Sort items before we return.
	sort.Sort(InfoSlice(infos))

	return infos, nil
}

// machineUserFromUsers gets machine user. Which may be different from machine
// owner when machine. is shared.
func machineUserFromUsers(users []machine.User) string {
	switch len(users) {
	case 1:
		return users[0].Username
	case 2:
		if !users[0].Owner {
			return users[0].Username
		}
		return users[1].Username
	default:
		return "<unknown>"
	}
}

// ownerFromUsers returns machine owner when machine is shared.
func ownerFromUsers(users []machine.User) string {
	if len(users) == 2 {
		if users[0].Owner {
			return users[0].Username
		}
		return users[1].Username
	}

	return ""
}
