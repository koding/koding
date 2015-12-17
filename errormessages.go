package main

import "fmt"

const (
	retryOrContactSupport        = "Please try again, or contact support@koding.com"
	waitRetryOrContactSupport    = "Please wait a moment and try again, or contact support@koding.com"
	retryNewCodeOrContactSupport = `Please go back to Koding to get a new code and try again, or contact support@koding.com`
)

var (
	// GenericInternalError is a generic error message. Typically used when we don't
	// want to reveal what exactly went wrong, like confusing implementation details.
	GenericInternalError = fmt.Sprintf(
		"Error: Encountered an internal error.\n%s", retryOrContactSupport,
	)

	// GenericInternalNewCodeError is a generic error message. Typically used when we
	// don't want to reveal what exactly went wrong, like confusing implementation
	// details.
	//
	// It instructs them to get a new code and try again.
	GenericInternalNewCodeError = fmt.Sprintf(
		"Error: Encountered an internal error.\n%s", retryNewCodeOrContactSupport,
	)

	// FailedInstallingKlient is generic for when a klient install fails.
	FailedInstallingKlient = fmt.Sprintf(
		"Error: Unable to install the %s.\n%s", KlientName, retryNewCodeOrContactSupport,
	)

	// FailedDownloadingKlient is used when downloading klient fails.
	FailedDownloadingKlient = fmt.Sprintf(
		"Error: Unable to download the %s binary.\n%s",
		KlientName, retryNewCodeOrContactSupport,
	)

	// FailedRegisteringKlient is used when registering klient to kontrol fails.
	FailedRegisteringKlient = fmt.Sprintf(
		"Error: Unable to authenticate %s to koding.com.\n%s",
		Name, retryNewCodeOrContactSupport,
	)

	// FailedVerifyingInstall is used when verifying the install fails.
	FailedVerifyingInstall = fmt.Sprintf(
		"Error: Unable to verify the installation of %s.\n%s",
		Name, retryNewCodeOrContactSupport,
	)

	// FailedStartKlient is used when starting klient fails.
	FailedStartKlient = fmt.Sprintf(
		"Error: Failed to start the %s within the expected time.\n%s", KlientName, retryOrContactSupport,
	)

	// FailedStopKlient is used when stopping klient fails.
	FailedStopKlient = fmt.Sprintf(
		"Error: Failed to stop the %s within the expected time.\n%s", KlientName, retryOrContactSupport,
	)

	// FailedGetSSHKey is used when we fail to get the ssh key
	FailedGetSSHKey = fmt.Sprintf(
		"Error: Failed to get ssh key.\n%s", retryOrContactSupport,
	)

	// CannotSSHManaged is used when the managed machine has a different username
	// than the current user. A temporary error, for a temporary limitation.
	CannotSSHManaged = "Error: Currently unable to ssh into managed machines."

	// FailedListMachines is a generic remote.list error. We include wait a moment
	// to retry, since this is often connection related.
	FailedListMachines = fmt.Sprintf(
		"Error: Failed to list machines.\n%s", waitRetryOrContactSupport,
	)

	// CannotMountDirNotExist is used when the user chooses not to make the dir on
	// mount. Can't mount to something that doesn't exist.
	CannotMountDirNotExist = "Error: Cannot mount a directory that does not exist, exiting..."

	// FailedToCreateMountDir is used when the user chose to create the dir, but it
	// failed for some reason.
	FailedToCreateMountDir = fmt.Sprintf(
		"Error: Failed to create the given mount directory.\n%s", retryOrContactSupport,
	)

	// FailedToMount is a generic failed to mount error.
	FailedToMount = fmt.Sprintf(
		"Error: Failed to mount the given directory.\n%s", retryOrContactSupport,
	)

	// FailedToUnmount is a generic failed to unmount error.
	FailedToUnmount = fmt.Sprintf(
		"Error: Failed to unmount the given directory.\n%s", retryOrContactSupport,
	)

	// FailedToLockMount instructs the user to unmount and mount again, since the
	// actual mount likely succeeded, only the locking failed.
	FailedToLockMount = `Error: Failed to lock the mount.
Please unmount and try again, or contact support@koding.com if this issue persists.`

	// FailedToUnlockMount is when we fail to unlock the given directory.
	//
	// TODO: What can we instruct the user to do here?
	FailedToUnlockMount = "Warning: Failed to unlock mount."
)
