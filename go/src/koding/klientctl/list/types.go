package list

import (
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
