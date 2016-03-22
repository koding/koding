package remote

import (
	"encoding/json"

	"github.com/koding/kite"

	"koding/fuseklient"
	"koding/klient/remote/mount"
	"koding/klient/remote/rsync"
	"koding/mountcli"
)

const (
	mountsStorageKey = "mounted_folders"
)

// MountsHandler lists all of the locally mounted folders
func (r *Remote) MountsHandler(req *kite.Request) (interface{}, error) {
	return r.mounts, nil
}

// AddMount adds the given Mount struct to the mounts slice, and saves it
// to the db.
func (r *Remote) AddMount(m *mount.Mount) error {
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

// RemoveMount removes the given Mount struct from the mounts slice, and
// saves the change to the db.
func (r *Remote) RemoveMount(m *mount.Mount) error {
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
	remoteMachines, err := r.GetMachines()
	if err != nil {
		return err
	}

	// Now, loop through our mounts and compare them to the fsMounts,
	// acting as needed.
	for _, m := range r.mounts {
		// The two New methods is to tweak how the log is displayed.
		log := r.log.New("restoreMounts").New(
			"mountName", m.MountName,
			"mountFolder", m.MountFolder.LocalPath,
			"prefetchAll", m.MountFolder.PrefetchAll,
		)

		fsMountName, _ := mountcli.NewMountcli().FindMountNameByPath(m.LocalPath)
		if fsMountName != "" {
			failOnUnmount := true

			// Mount path exists, but the name doesn't match our mount name.
			// This occurs if the folder has been mounted by something else (ie,
			// the user), so to be safe we should not mount this folder.
			if fsMountName != m.MountName {
				log.Warning(
					"The path %q has a fs mountName of %q, but %q was expected.",
					m.LocalPath, fsMountName, m.MountName,
				)

				failOnUnmount = false
			}

			log.Info("Automatically unmounting")

			m.Log = mount.MountLogger(m, log)

			// Mount path exists, and the names match. Unmount it, so that we
			// can remount it below.
			if err := m.Unmount(); err != nil {
				if failOnUnmount {
					log.Error("Failed to automatically unmount. err:%s", err)
					continue
				} else {
					log.Error("Failed to automatically unmount, but ignoring unmount error. Continuing. err:%s", err)
				}
			}
		}

		// Mount path has been unmounted, or didn't exist locally.
		// Remount it, to improve UX.
		log.Info("Automatically mounting")

		remoteMachine, err := remoteMachines.GetByIP(m.IP)
		if err != nil {
			log.Error("Failed to get machine by ip. err:%s", err)
			continue
		}

		// Construct our mounter
		mounter := &mount.Mounter{
			Log:           log,
			Options:       m.MountFolder,
			IP:            remoteMachine.IP,
			KiteTracker:   remoteMachine.KiteTracker,
			Transport:     remoteMachine.Client,
			PathUnmounter: fuseklient.Unmount,
		}

		if err := mounter.MountExisting(m); err != nil {
			m.LastMountError = true
			log.Error("Mounter returned error. err:%s", err)

			continue
		}

		if !m.SyncIntervalOpts.IsZero() {
			rs := rsync.NewClient(r.log)
			// After the progress chan is done, start our SyncInterval
			startIntervaler(log, remoteMachine, rs, m.SyncIntervalOpts)
			// Assign the rsync intervaler to the mount.
			m.Intervaler = remoteMachine.Intervaler
		} else {
			log.Warning(
				"Unable to restore Interval for remote, SyncOpts is zero value. This likely means that SyncOpts were not saved or didn't exist in the previous binary. machineName:%s",
				remoteMachine.Name,
			)
		}
	}

	return nil
}
