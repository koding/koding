package list

import (
	"koding/klientctl/util"
	"time"
)

type KiteInfo struct {
	ConnectedAt  time.Time   `json:"connectedAt"`
	IP           string      `json:"ip"`
	VMName       string      `json:"vmName"`
	Hostname     string      `json:"hostname"`
	MachineLabel string      `json:"machineLabel"`
	Mounts       []MountInfo `json:"mounts"`
	Teams        []string    `json:"teams"`

	// TODO: DEPRECATE
	MountedPaths []string `json:"mountedPaths"`
}

// KiteInfos is a slice of KiteInfo with helper methods.
type KiteInfos []KiteInfo

type MountInfo struct {
	RemotePath string `json:"remotePath"`
	LocalPath  string `json:"localPath"`
}

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
