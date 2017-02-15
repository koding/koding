package mount

import "errors"

// Mounts is a basic slice of Mount, providing convenience sorting methods.
type Mounts []*Mount

// ContainsMount returns whether the givne mount is in the Mounts slice.
func (ms Mounts) ContainsMount(containsMount *Mount) bool {
	for _, sliceMount := range ms {
		if containsMount == sliceMount {
			return true
		}
	}

	return false
}

// FindByName sorts through the Mounts, returning the first Mount with a
// matching name.
//
// TODO: Make this func signature consistent with the other GetByX methods.
func (ms Mounts) FindByName(name string) (*Mount, bool) {
	for _, m := range ms {
		if m.MountName == name {
			return m, true
		}
	}

	return nil, false
}

// RemoveByName returns a new list with the first occurrence given name removed.
func (ms Mounts) RemoveByName(name string) (Mounts, error) {
	for i, m := range ms {
		if m.MountName == name {
			return append(ms[:i], ms[i+1:]...), nil
		}
	}

	return nil, errors.New("Name not found")
}

// IsDuplicate compares the given ip, remote and local folders to all of the
// mounts in the slice. If a Mount is found with matching data, it is
// considered a duplicate.
//
// Duplicate is decided in two main ways:
//
// 1. It has the same local path. Two mounts cannot occupy the same local
// path, so a matching local means it is duplicate.
//
// 2. The remote folder *and* IP are the same.
func (ms Mounts) IsDuplicate(ip, remote, local string) bool {
	for _, m := range ms {
		// If the local is already in use, it's a duplicate mount
		if m.LocalPath == local {
			return true
		}

		// If *both* the remote Ip and Path are in use, it's a duplicate
		// mount
		//
		// TODO: Confirm that this is cared about. I suspect not.
		if m.IP == ip && m.RemotePath == remote {
			return true
		}
	}
	return false
}

// GetByLocalPath sorts through the Mounts slice, returning the first Mount
// with a matching local Path.
//
// TODO: Make this func signature consistent with the other GetByX methods.
func (ms Mounts) GetByLocalPath(local string) *Mount {
	for _, m := range ms {
		if m.LocalPath == local {
			return m
		}
	}

	return nil
}
