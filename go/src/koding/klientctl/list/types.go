package list

import (
	"koding/klient/remote/machine"
	"koding/klient/remote/restypes"
	"koding/klientctl/util"
)

type KiteInfo struct {
	restypes.ListMachineInfo
}

// KiteInfos is a slice of KiteInfo with helper methods.
type KiteInfos []KiteInfo

// FindFromName finds a specific KiteInfo by the name, returning true or false if
// one was found.
func (infos KiteInfos) FindFromName(name string) (KiteInfo, bool) {
	infoNames := make([]string, len(infos), len(infos))
	for _, info := range infos {
		infoNames = append(infoNames, info.VMName)
	}

	matchedName, ok := util.MatchFullOrShortcut(infoNames, name)
	if !ok {
		return KiteInfo{}, false
	}

	for _, info := range infos {
		if info.VMName == matchedName {
			return info, true
		}
	}

	return KiteInfo{}, false
}

func (s KiteInfos) Len() int {
	return len(s)
}

func (s KiteInfos) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}

// Kite infos are sorted by "Groups" of machines. We define a group
// as a logical collection, such as online machines, mounted machines,
// etc.
func (s KiteInfos) Less(i, j int) bool {
	switch {
	case groupRank(s[i]) < groupRank(s[j]):
		return true
	case groupRank(s[i]) == groupRank(s[j]):
		return s[i].VMName < s[j].VMName
	default:
		return false
	}
}

func groupRank(k KiteInfo) int {
	switch {
	case isInMountGroup(k):
		return 0
	case isInOnlineGroup(k):
		return 1
	case isInOfflineGroup(k):
		return 2
	default:
		return 3
	}
}

func isInMountGroup(k KiteInfo) bool {
	if k.MachineStatus == machine.MachineError {
		return true
	}

	if k.MachineStatus == machine.MachineRemounting {
		return true
	}

	if len(k.Mounts) != 0 {
		return true
	}

	return false
}

func isInOnlineGroup(k KiteInfo) bool {
	if k.MachineStatus == machine.MachineOnline {
		return true
	}

	return false
}

func isInOfflineGroup(k KiteInfo) bool {
	if k.MachineStatus == machine.MachineOffline {
		return true
	}

	return false
}
