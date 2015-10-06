package fs

import "github.com/cloudfoundry/gosigar"

func ListMounts() map[string]string {
	fslist := sigar.FileSystemList{}
	fslist.Get()

	list := map[string]string{}
	for _, fs := range fslist.List {
		list[fs.DevName] = fs.DirName
	}

	return list
}

func ListMountByName(name string) (string, bool) {
	list := ListMounts()
	for mountName, mountPath := range list {
		if mountName == name {
			return mountPath, true
		}
	}

	return "", false
}

func ListMountByPath(path string) (string, bool) {
	list := ListMounts()
	for mountName, mountPath := range list {
		if mountPath == path {
			return mountName, true
		}
	}

	return "", false
}
