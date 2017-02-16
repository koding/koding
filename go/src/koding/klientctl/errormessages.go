package main

import (
	"fmt"
	"koding/klientctl/config"
	"koding/klientctl/errormessages"
)

const (
	waitRetry    = "Please wait a moment and try again."
	retryNewCode = `Please go back to Koding to get a new code and try again.`
)

var (
	// GenericInternalError is a generic error message. Typically used when we don't
	// want to reveal what exactly went wrong, like confusing implementation details.
	GenericInternalError = fmt.Sprintf(
		"Error: Encountered an internal error.\n%s",
	)

	// KlientIsntRunning is an error printed to the user if klient is not running.
	// Usually from the health checker.
	KlientIsntRunning = fmt.Sprintf(
		`Error: The %s does not appear to be running. Please run
the following command to start it:

    sudo kd start
`,
		config.KlientName,
	)

	// GenericInternalNewCodeError is a generic error message. Typically used when we
	// don't want to reveal what exactly went wrong, like confusing implementation
	// details.
	//
	// It instructs them to get a new code and try again.
	GenericInternalNewCodeError = fmt.Sprintf(
		"Error: Encountered an internal error.\n%s", retryNewCode,
	)

	// FailedInstallingKlient is generic for when a klient install fails.
	FailedInstallingKlient = fmt.Sprintf(
		"Error: Unable to install the %s.\n%s", config.KlientName, retryNewCode,
	)

	// FailedDownloadingKlient is used when downloading klient fails.
	FailedDownloadingKlient = fmt.Sprintf(
		"Error: Unable to download the %s binary.\n%s",
		config.KlientName, retryNewCode,
	)

	// FailedRegisteringKlient is used when registering klient to kontrol fails.
	FailedRegisteringKlient = fmt.Sprintf(
		"Error: Unable to authenticate %s to koding.com.\n%s",
		config.Name, retryNewCode,
	)

	// FailedStartKlient is used when starting klient fails.
	FailedStartKlient = fmt.Sprintf(
		"Error: Failed to start the %s within the expected time.\n", config.KlientName,
	)

	// FailedStopKlient is used when stopping klient fails.
	FailedStopKlient = fmt.Sprintf(
		"Error: Failed to stop the %s within the expected time.\n", config.KlientName,
	)

	// FailedListMachines is a generic remote.list error. We include wait a moment
	// to retry, since this is often connection related.
	FailedListMachines = fmt.Sprintf(
		"Error: Failed to list machines.\n%s", waitRetry,
	)

	// ReconnectingToKontrol is used when we have encountered specific errors pertaining
	// to being disconnected from kontrol. This should be used *after* a proper health
	// check, because if their internet is down, it's more meaningful than saying
	// we are reconnecting to Koding.
	//
	// Plus, if they get no internet, and *then* reconnecting, it shows we are making
	// progress in restoring functionality.
	ReconnectingToKontrol = fmt.Sprintf(
		`%s has been disconnected from Koding, and is in the process of reconnecting.
Please wait a few minutes and try again.`,
		config.Name,
	)

	// CannotMountPathExists is used when the user provides a path that already
	// exists.
	CannotMountPathExists = "Error: given path already exists. Please remove and try again."

	// given path. A possible example might be that the user asked to mount to
	// /root/foo and kd doesn't have permission to even look in that directory.
	//
	// /root/foo might not exist, but kd can't even read it.
	//
	// TODO: Write meaningful message.
	CannotMountUnableToOpenPath = "Error: Unable to open the given path"

	// FailedToMount is a generic failed to mount error.
	FailedToMount = fmt.Sprintf(
		"Error: Failed to mount the given directory.\n",
	)

	// FailedToUnmount is a generic failed to unmount error.
	FailedToUnmount = fmt.Sprintf(
		"Error: Failed to unmount the given directory.\n",
	)

	// FailedUninstallingKlientWarn is when the service fails
	// (connecting or uninstalling)
	FailedStopKlientWarn = fmt.Sprintf(
		"Warning: Unable to stop %s service.", config.Name,
	)

	// FailedUninstallingKlientWarn is when the service fails
	// (connecting or uninstalling)
	FailedUninstallingKlientWarn = fmt.Sprintf(
		"Warning: Unable to uninstall %s service.", config.Name,
	)

	// FailedToRemoveFiles is a generic failed to remove warning.
	FailedToRemoveFilesWarn = fmt.Sprintf(
		"Warning: Failed to remove %s files. This is not a critical issue.", config.Name,
	)

	// FailedToRemoveAuthFile for when we can't remove the kite key.
	FailedToRemoveAuthFileWarn = "Warning: Failed to remove authorization file. This is not a critical issue."

	// FailedToRemoveKlient for when we can't remove the klient binary.
	FailedToRemoveKlientWarn = fmt.Sprintf(
		"Warning: Failed to remove %s binary. This is not a critical issue.", config.Name,
	)

	// FailedCheckingUpdateAvailable is used when checking if an update failed.
	FailedCheckingUpdateAvailable = fmt.Sprintf(
		"Error: Failed to check if an update is available.\n",
	)

	// FailedDownloadUpdate is when downloading the update from s3 failed.
	FailedDownloadUpdate = fmt.Sprintf(
		"Error: Failed to download the update.\n",
	)

	// PrefetchAllAndMetaTogether is used when the user supplies both --prefetchall
	// and --noprefetchmeta, as they are incompatible flags.
	PrefetchAllAndMetaTogether = `Error: Cannot use both noprefetchmeta and prefetchall flags at the same time.
Please try again with just the --prefetchall flag.`

	// FailedDialingRemote is the generic message for when the local klient failed
	// to dial a remote klient. The api user of this message should also run a health
	// check, meaning that if this message is printed the users local internet
	// *should* be working and the blame for the failed dialing likely belongs to
	// the remote klient's internet.
	//
	// Note that of course, a race condition created by spotty internet in the above
	// scenario could create a false positive, blaming the remote end when it was
	// just a local internet hiccup.
	FailedDialingRemote = fmt.Sprintf(
		`Error: Unable to communicate with the remote machine. Please ensure that the
remote machine is running & accessible and try again.`,
	)

	// MachineMountActionIsLocked is used when the machine's mount(s) have been locked
	// by another kd call or auto mounting process. Ie, two calls to `kd mount` at
	// the same time for the same machine.
	MachineMountActionIsLocked = `Error: %s is currently busy with another mounting process.
Please try again in a moment.`

	// AttemptedRemoveRestrictedPath is when the user unmounts a path, but
	// the path cannot be removed because it is an important path.
	AttemptedRemoveRestrictedPath = fmt.Sprintf(
		`Warning: Unable to remove the mounted path, due to it being a protected path.`,
	)

	// UnmountFailedRemoveMountPath is used when we _(for some unknown reason)_ are
	// unable to remove the mount path. It could be due to permissions, the path
	// not being empty, or other unknown reasons.
	UnmountFailedRemoveMountPath = fmt.Sprintf(
		`Warning: The mount path was unable to be cleaned up after unmount.
Please remove this path before trying to mount again to this path. `,
	)

	// DEPRECATED LOCATION. Moved to errormessages package.
	MachineNotFound        = errormessages.MachineNotFound
	MountNotFound          = errormessages.MountNotFound
	FailedGetSSHKey        = errormessages.FailedGetSSHKey
	FailedPrefetchFolder   = errormessages.FailedPrefetchFolder
	MachineNotValidYet     = errormessages.MachineNotValidYet
	RemoteProcessFailed    = errormessages.RemoteProcessFailed
	RemotePathDoesNotExist = errormessages.RemotePathDoesNotExist
	CannotFindSSHUser      = errormessages.CannotFindSSHUser
)
