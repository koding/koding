package remote

import (
	"encoding/json"

	"github.com/koding/kite"

	"koding/fuseklient"
	"koding/klient/remote/machine"
	"koding/klient/remote/mount"
	"koding/klient/remote/rsync"
	"koding/mountcli"
	"time"
)

const (
	mountsStorageKey = "mounted_folders"

	// Messages displayed to the user about the machines status.
	autoRemountFailed = "Error remounting during restart. Please unmount & mount again."
	autoRemounting    = "Remounting after restart. Please wait..."
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
	log := r.log.New("restoreMounts queue")

	// Store our mounts locally, so that modificatons to the slice
	// don't propagate to the actual mounts slice
	remountQueue := append([]*mount.Mount(nil), r.mounts...)
	totalMounts := len(remountQueue)

	// Set the mounts to remounting status. Any failures in the function are logged and
	// ignored.
	r.markMountsAsRemounting(remountQueue)

	// Loop until there are no more mounts in the remountQueue.
	var m *mount.Mount
	for attempt := 0; len(remountQueue) > 0 && attempt < r.maxRestoreAttempts; attempt++ {
		// To prevent spamming remount attempts,
		if attempt >= totalMounts {
			time.Sleep(r.restoreFailuresPause)
		}

		// Shift the mount off of the slice
		m, remountQueue = remountQueue[0], remountQueue[1:]

		log := log.New(
			"mountName", m.MountName,
			"mountFolder", m.MountFolder.LocalPath,
			"prefetchAll", m.MountFolder.PrefetchAll,
		)

		if err := r.restoreMount(m); err != nil {
			log.Error(
				"Failed to restore mount, attempt #%d. Retrying after queue. err:%s",
				attempt, err,
			)

			// Push it back to the end of the queue, because this mount failed.
			remountQueue = append(remountQueue, m)
		}
	}

	log.Info("Remounting successfully done.")
	return nil
}

// Mark all the machines as remounting. Note that because restoreMounts should not
// return any errors, we can't actually deal with a failure here. This is primarily
// a helper function.
func (r *Remote) markMountsAsRemounting(mounts []*mount.Mount) {
	log := r.log.New("markMountsAsRemounting")

	remoteMachines, err := r.GetMachines()
	if err != nil {
		log.Warning(
			"Failed to get machines, unable to set status to remounting.. err:%s", err,
		)
		return
	}

	// Loop through all the mounts, and mark them as remounting first.
	for _, m := range mounts {
		remoteMachine, err := remoteMachines.GetByIP(m.IP)
		if err != nil {
			log.Warning(
				"Failed to get machine by ip, unable to set status to remounting. mount:%s, err:%s",
				m.MountName, err,
			)

			// Move onto next machine.
			continue
		}

		remoteMachine.SetStatus(machine.MachineRemounting, autoRemounting)
	}
}

func (r *Remote) restoreMount(m *mount.Mount) error {
	if r.mockedRestoreMount != nil {
		return r.mockedRestoreMount(m)
	}

	remoteMachines, err := r.GetMachines()
	if err != nil {
		return err
	}

	// The two New methods is to tweak how the log is displayed.
	log := r.log.New("restoreMount").New(
		"mountName", m.MountName,
		"mountFolder", m.MountFolder.LocalPath,
		"prefetchAll", m.MountFolder.PrefetchAll,
	)

	remoteMachine, err := remoteMachines.GetByIP(m.IP)
	if err != nil {
		log.Error("Failed to get machine by ip. err:%s", err)
		return err
	}

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
				return err
			} else {
				log.Error(
					"Failed to automatically unmount, but ignoring unmount error. Continuing. err:%s",
					err,
				)
			}
		}
	}

	// Mount path has been unmounted, or didn't exist locally.
	// Remount it, to improve UX.
	log.Info("Automatically mounting")

	// Construct our mounter
	mounter := &mount.Mounter{
		Log:           log,
		Options:       m.MountFolder,
		Machine:       remoteMachine,
		IP:            remoteMachine.IP,
		KiteTracker:   remoteMachine.KiteTracker,
		Transport:     remoteMachine,
		PathUnmounter: fuseklient.Unmount,
	}

	if err := mounter.MountExisting(m); err != nil {
		return err
	}

	// remote.cache is normally responsible for creating the intervaler, but
	// because cache is not creating one here, we need to do it manually.
	if remoteMachine.Intervaler == nil {
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

	// If there's no errors, clear the status.
	remoteMachine.SetStatus(machine.MachineStatusUnknown, "")
	return nil
}
