package machine

import (
	"strings"
	"time"
)

// Info stores the basic information about the machine.
type Info struct {
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

	// CreatedAt tells about machine age.
	CreatedAt time.Time `json:"createdAt"`

	// The machines last known status.
	Status Status `json:"status"`

	// The user name of the Koding user.
	Username string `json:"username"`

	// Owner describes who shared the machine if it's shared.
	Owner string `json:"owner"`

	// Alias it a human friendly "name" of the machine.
	Alias string `json:"alias"`

	// Mounts represents current mounts to the machine.
	//
	// TODO(ppknap) implement or remove from machine info.
	Mounts []ListMountInfo `json:"mounts"`
}

// Status represents the current status of machine.
type Status struct {
	State      State     `json:"state"`
	Reason     string    `json:"reason"`
	ModifiedAt time.Time `json:"modifiedAt"`
}

// ListMountInfo is the machine info response from the `remote.list` handler.
type ListMountInfo struct {
	MountName  string `json:"mountName"`
	RemotePath string `json:"remotePath"`
	LocalPath  string `json:"localPath"`
	MountType  int    `json:"mountType"`
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
	case i.Status.State == StateRemounting || len(i.Mounts) != 0: // Mounted machines first.
		return 0
	case i.Status.State == StateError: // Mounting has failed.
		return 1
	case i.Status.State == StateOnline: // On-line machines.
		return 2
	case i.Status.State == StateOffline: // Off-line machines.
		return 3
	default:
		return 4
	}
}

// FindByName finds a specific machine Info by its name.
func (s InfoSlice) FindByName(name string) *Info {
	infoNames := make([]string, 0, len(s))
	for _, info := range s {
		infoNames = append(infoNames, info.Alias)
	}

	matchedName, ok := matchFullOrShortcut(infoNames, name)
	if !ok {
		return nil
	}

	for _, info := range s {
		if info != nil && info.Alias == matchedName {
			return info
		}
	}

	return nil
}

// matchFullOrShortcut matches string in a slice of strings if provided name
// is equal to an item or the item starts with provided name.
func matchFullOrShortcut(items []string, name string) (string, bool) {
	var (
		match   string
		matched bool
	)

	for _, item := range items {
		if item == name {
			return item, true
		}

		if strings.HasPrefix(item, name) {
			match = item
			matched = true
		}
	}

	return match, matched
}
