package machine

import (
	"errors"
	"sort"
	"time"

	"koding/kites/kloud/machine"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	kmachine "koding/klient/machine"
	"koding/klient/machine/machinegroup"
)

// IdentifiersOptions stores options for "machine identifiers" call.
type IdentifiersOptions struct {
	IDs     bool
	Aliases bool
	IPs     bool
}

// Identifiers returns cached machine identifiers.
func (c *Client) Identifiers(options *IdentifiersOptions) ([]string, error) {
	identifiersReq := &machinegroup.IdentifierListRequest{
		IDs:     options.IDs,
		Aliases: options.Aliases,
		IPs:     options.IPs,
	}
	var identifiersRes machinegroup.IdentifierListResponse

	if err := c.klient().Call("machine.identifier.list", identifiersReq, &identifiersRes); err != nil {
		return nil, err
	}

	return identifiersRes.Identifiers, nil
}

// ListOptions stores options for `machine list` call.
type ListOptions struct {
	MachineID string
}

// List retrieves user's machines from kloud.
func (c *Client) List(options *ListOptions) ([]*Info, error) {
	if options == nil {
		return nil, errors.New("invalid nil options")
	}

	listReq := &stack.MachineListRequest{
		MachineID: options.MachineID,
	}
	var listRes stack.MachineListResponse

	// Get info from kloud.
	if err := c.kloud().Call("machine.list", listReq, &listRes); err != nil {
		return nil, err
	}

	// Register machines to klient and get aliases.
	createReq := &machinegroup.CreateRequest{
		Addresses: make(map[kmachine.ID][]kmachine.Addr),
		Metadata:  make(map[kmachine.ID]*kmachine.Metadata),
	}
	var createRes machinegroup.CreateResponse

	for _, m := range listRes.Machines {
		createReq.Addresses[kmachine.ID(m.ID)] = []kmachine.Addr{
			{
				Network:   "ip",
				Value:     m.IP,
				UpdatedAt: time.Now(),
			},
			{
				Network:   "kite",
				Value:     m.QueryString,
				UpdatedAt: time.Now(),
			},
			{
				Network:   "http",
				Value:     m.RegisterURL,
				UpdatedAt: time.Now(),
			},
		}
		createReq.Metadata[kmachine.ID(m.ID)] = &kmachine.Metadata{
			Owner: ownerFromUsers(m.Users),
			Label: m.Label,
			Stack: m.Stack,
			Team:  m.Team,
		}
	}

	if err := c.klient().Call("machine.create", createReq, &createRes); err != nil {
		return nil, err
	}

	infos := make([]*Info, len(listRes.Machines))
	for i, m := range listRes.Machines {
		infos[i] = &Info{
			ID:          m.ID,
			Alias:       createRes.Aliases[kmachine.ID(m.ID)],
			Team:        m.Team,
			Stack:       m.Stack,
			Provider:    m.Provider,
			Label:       m.Label,
			IP:          m.IP,
			QueryString: m.QueryString,
			RegisterURL: m.RegisterURL,
			CreatedAt:   m.CreatedAt,
			Status: kmachine.MergeStatus(kmachine.Status{
				State:  fromMachineStateString(m.Status.State),
				Reason: m.Status.Reason,
				Since:  m.Status.ModifiedAt,
			}, createRes.Statuses[kmachine.ID(m.ID)]),
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

// ms2State maps machinestate states to State objects.
var ms2State = map[machinestate.State]kmachine.State{
	machinestate.NotInitialized: kmachine.StateOffline,
	machinestate.Building:       kmachine.StateOffline,
	machinestate.Starting:       kmachine.StateOffline,
	machinestate.Running:        kmachine.StateOnline,
	machinestate.Stopping:       kmachine.StateOffline,
	machinestate.Stopped:        kmachine.StateOffline,
	machinestate.Rebooting:      kmachine.StateOffline,
	machinestate.Terminating:    kmachine.StateOffline,
	machinestate.Terminated:     kmachine.StateOffline,
	machinestate.Snapshotting:   kmachine.StateOffline,
	machinestate.Pending:        kmachine.StateOffline,
	machinestate.Unknown:        kmachine.StateUnknown,
}

// FromMachineStateString converts machinestate string to State object.
func fromMachineStateString(raw string) kmachine.State {
	return ms2State[machinestate.States[raw]]
}

// Identifiers returns cached machine identifiers using DefaultClient.
func Identifiers(opts *IdentifiersOptions) ([]string, error) { return DefaultClient.Identifiers(opts) }

// List retrieves user's machines from kloud using DefaultClient.
func List(opts *ListOptions) ([]*Info, error) { return DefaultClient.List(opts) }
