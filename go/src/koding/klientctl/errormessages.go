package main

import (
	"fmt"
	"koding/klientctl/config"
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

	// FailedVerifyingInstall is used when verifying the install fails.
	FailedVerifyingInstall = fmt.Sprintf(
		"Error: Unable to verify the installation of %s.\n%s",
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

	// FailedGetSSHKey is used when we fail to get the ssh key
	FailedGetSSHKey = fmt.Sprintf("Error: Failed to get ssh key.\n")

	// CannotSSHManaged is used when the managed machine has a different username
	// than the current user. A temporary error, for a temporary limitation.
	CannotSSHManaged = "Error: Currently unable to ssh into managed machines."

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

	// CannotMountDirNotExist is used when the user chooses not to make the dir on
	// mount. Can't mount to something that doesn't exist.
	CannotMountDirNotExist = "Error: Cannot mount a directory that does not exist, exiting..."

	// CannotMountPathExists is used when the user provides a path that already
	// exists.
	CannotMountPathExists = "Error: given path already exists. Please remove and try again."

	// MachineNotFound is a generic machine not found message.
	MachineNotFound = "Error: Machine not found. Please enter a valid machine name as shown in kd list."

	// MountNotFound is a generic mount not found message.
	MountNotFound = "Error: Mount not found."

	// given path. A possible example might be that the user asked to mount to
	// /root/foo and kd doesn't have permission to even look in that directory.
	//
	// /root/foo might not exist, but kd can't even read it.
	//
	// TODO: Write meaningful message.
	CannotMountUnableToOpenPath = "Error: Unable to open the given path"

	// FailedToCreateMountDir is used when the user chose to create the dir, but it
	// failed for some reason.
	FailedToCreateMountDir = fmt.Sprintf(
		"Error: Failed to create the given mount directory.\n",
	)

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

	// FailedPrefetchFolder is used when remote.cacheFolder fails.
	FailedPrefetchFolder = fmt.Sprintf(
		"Error: Failed to prefetch the requested folder.\n",
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

	// MachineNotValidYet occurs when the kontrol has not yet returned a client
	// for the given machine. Likely meaning the machine has not been online
	// since klient has last restarted.
	//
	// Since the above DialingRemote error is generic enough, we're just using that
	// for now.
	MachineNotValidYet = FailedDialingRemote

	// RemotePathDoesNotExist is printed when the user supplies a directory to mount,
	// that does not exist on the remote side.
	RemotePathDoesNotExist = fmt.Sprintf(
		`Error: The given path does not exist on the remote machine.`,
	)

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
)
