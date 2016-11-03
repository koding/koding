package machine

import "time"

// Info stores the basic information about the machine.
type Info struct {
	// The machines last known status.
	Status Status `json:"machineStatus"`

	// The message (if any) associated with the machine status.
	StatusMessage string `json:"statusMessage"`

	// The last time this machine was online. This may be zero valued if the
	// machine has not been online since Klient was restarted.
	OnlineAt time.Time `json:"onlineAt"`

	// The Ip of the running machine.
	IP string `json:"ip"`

	// The human friendly "name" of the machine.
	VMName string `json:"vmName"`

	// The machine label, as seen by the koding ui
	MachineLabel string `json:"machineLabel"`

	// The team names for the remote machine, if any
	Teams []string `json:"teams"`

	Mounts []ListMountInfo `json:"mounts"`

	// The username of the koding user.
	Username string
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
		return s[i].VMName < s[j].VMName
	default:
		return false
	}
}

func groupRank(i *Info) int {
	if i == nil {
		return -1
	}

	switch {
	case i.Status == StatusRemounting, len(i.Mounts) != 0: // Mounted machines first.
		return 0
	case i.Status == StatusError: // Mounting has failed.
		return 1
	case i.Status == StatusOnline: // On-line machines.
		return 2
	case i.Status == StatusOffline: // Off-line machines.
		return 3
	default:
		return 4
	}
}

// FindByName finds a specific machine Info by its name.
func (s InfoSlice) FindByName(name string) *Info {
	infoNames := make([]string, 0, len(s))
	for _, info := range s {
		infoNames = append(infoNames, info.VMName)
	}

	matchedName, ok := matchFullOrShortcut(infoNames, name)
	if !ok {
		return nil
	}

	for _, info := range infos {
		if info != nil && info.VMName == matchedName {
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
