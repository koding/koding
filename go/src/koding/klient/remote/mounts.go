package remote

import (
	"encoding/json"
	"errors"
	"time"

	"github.com/koding/kite"

	"koding/fuseklient"
	"koding/klient/remote/kitepinger"
	"koding/klient/remote/req"
	"koding/klient/remote/rsync"
)

const (
	mountsStorageKey = "mounted_folders"
)

// Mount stores information about mounted folders, and is both with
// to various Remote.* kite methods as well as being saved in
// klient's storage.
type Mount struct {
	req.MountFolder

	IP        string `json:"ip"`
	MountName string `json:"mountName"`

	// The options used for the local Intervaler. Used to store and retrieve from
	// the database.
	SyncIntervalOpts rsync.SyncIntervalOpts `json:"syncIntervalOpts"`

	// The intervaler for this mount, used to update the remote.cache, if it exists.
	//
	// Note: If remote.cache is not called, or not called with an interval, this
	// will be null. Check before using.
	intervaler rsync.SyncIntervaler

	// The channel that sends notification of connection statuses on. This may be
	// nil unless the Mount is actively started and subscribed.
	pingerSub chan kitepinger.ChangeSummary

	// A kitepinger reference from the parent machine, so that Mounts can unsub as
	// needed.
	kitePinger kitepinger.KitePinger

	MountedFS *fuseklient.KodingNetworkFS `json:"-"`

	// mockable interfaces and types, used for testing and abstracting the environment
	// away.

	// the mountedFs Unmounter
	unmounter interface {
		Unmount() error
	}
}

// Mounts is a basic slice of Mount, providing convenience sorting methods.
type Mounts []*Mount

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

// RemoveByName returns a new list with the first occurence given name removed.
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

// MountsHandler lists all of the locally mounted folders
func (r *Remote) MountsHandler(req *kite.Request) (interface{}, error) {
	return r.mounts, nil
}

// addMount adds the given Mount struct to the mounts slice, and saves it
// to the db.
func (r *Remote) addMount(m *Mount) error {
	mounts := append(r.mounts, m)

	data, err := json.Marshal(mounts)
	if err != nil {
		return err
	}

	if err := r.storage.Set(mountsStorageKey, string(data)); err != nil {
		return err
	}

	// Add it after we've been successful
	r.mounts = mounts

	return nil
}

// removeMount removes the given Mount struct from the mounts slice, and
// saves the change to the db.
func (r *Remote) removeMount(m *Mount) error {
	mounts, err := r.mounts.RemoveByName(m.MountName)
	if err != nil {
		return err
	}

	data, err := json.Marshal(mounts)
	if err != nil {
		return err
	}

	if err = r.storage.Set(mountsStorageKey, string(data)); err != nil {
		return err
	}

	// Add it after we've been successful
	r.mounts = mounts

	return nil
}

// loadMounts loads the marshalled mounts from storage and *replaces* the
// existing mounts instance with them.
func (r *Remote) loadMounts() error {
	// TODO: Figure out how to filter the "key not found error", so that
	// we don't ignore all errors.
	data, _ := r.storage.Get(mountsStorageKey)

	// If there is no data, we have nothing to load.
	if data == "" {
		return nil
	}

	return json.Unmarshal([]byte(data), &r.mounts)
}

// restoreMounts will analyze the current mount list and fix and broken
// mounts that may have been caused by process crash, os restart, etc.
func (r *Remote) restoreMounts() error {
	remoteMachines, err := r.GetKites()
	if err != nil {
		return err
	}

	// Now, loop through our mounts and compare them to the fsMounts,
	// acting as needed.
	for _, m := range r.mounts {
		// Ignoring the error here, because it is not a problem if there is
		// no mountName for the given path.
		fsMountInfo, _ := fuseklient.GetMountByPath(m.LocalPath)

		if fsMountInfo != nil {
			fsMountName := fsMountInfo.FSName

			// Mount path exists, but the name doesn't match our mount name.
			// This occurs if the folder has been mounted by something else (ie,
			// the user), so to be safe we should not mount this folder.
			//
			// TODO: Possibly store all of these drops? That way we can inform
			// the user if the user calls this func via some klient method.
			if fsMountName != m.MountName {
				r.log.Warning(
					"resolveMounts: The path '%s' has a fs mountName of '%s', but "+
						"'%s' was expected. Removing the mount from Klient.",
					m.LocalPath, fsMountName, m.MountName,
				)
				r.removeMount(m)
				// Since we're removing this mount from the list, we don't want to
				// unmount/modify/etc the mount. We can skip it.
				continue
			}

			// Mount path exists, and the names match. Unmount it, so that we
			// can remount it below.
			r.log.Debug("Automatically unmounting '%s'", m.LocalPath)
			if err := fuseklient.Unmount(m.LocalPath); err != nil {
				return err
			}
		}

		// Mount path has been unmounted, or didn't exist locally.
		// Remount it, to improve UX.
		r.log.Debug("Automatically mounting '%s'", m.LocalPath)

		remoteMachine, err := remoteMachines.GetByIP(m.IP)
		if err != nil {
			return err
		}

		// Now that we have the remoteMachine, apply the kitePinger reference.
		m.kitePinger = remoteMachine.kitePinger

		kiteClient := remoteMachine.Client
		if err := kiteClient.Dial(); err != nil {
			return err
		}

		// Create our changes channel, so that fuseMount can be told when we lose and
		// reconnect to klient.
		changeSummaries := make(chan kitepinger.ChangeSummary, 1)
		changes := changeSummaryToBool(changeSummaries)

		if err = fuseMountFolder(m, kiteClient); err != nil {
			return err
		}

		go watchClientAndReconnect(
			r.log, remoteMachine, m, kiteClient,
			changeSummaries, changes,
		)

		if !m.SyncIntervalOpts.IsZero() {
			rs := rsync.NewClient(r.log)
			// After the progress chan is done, start our SyncInterval
			startIntervaler(r.log, remoteMachine, rs, m.SyncIntervalOpts)
			// Assign the rsync intervaler to the mount.
			m.intervaler = remoteMachine.intervaler
		} else {
			r.log.Warning(
				"Unable to restore Interval for remote, SyncOpts is zero value. This likely means that SyncOpts were not saved or didn't exist in the previous binary. machineName:%s",
				remoteMachine.Name,
			)
		}
	}

	return nil
}

// watchClientAndReconnect
func watchClientAndReconnect(log kite.Logger, machine *Machine, mount *Mount, kiteClient *kite.Client, changeSummaries chan kitepinger.ChangeSummary, changes <-chan bool) {
	kiteClient.Reconnect = true

	log.Info(
		"Monitoring Klient connection.. Ip:%s, machineName:%s, localPath:%s",
		machine.IP, machine.Name, mount.LocalPath,
	)

	machine.kitePinger.Subscribe(changeSummaries)
	machine.kitePinger.Start()
	mount.pingerSub = changeSummaries

	for summary := range changeSummaries {
		if summary.OldStatus == kitepinger.Failure && summary.OldStatusDur > time.Minute*30 {

			log.Info(
				"Remounting directory after reconnect. Disconnected for:%s, machineName:%s, localPath:%s",
				summary.OldStatusDur, machine.Name, mount.LocalPath,
			)

			// Log error and return to exit loop, since something is broke
			if err := fuseklient.Unmount(mount.LocalPath); err != nil {
				log.Error(err.Error())
				return
			}

			if err := fuseMountFolder(mount, kiteClient); err != nil {
				log.Error(err.Error())
			}
		}
	}
}
