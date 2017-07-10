package main

import (
	"fmt"
	"koding/klientctl/config"
)

const (
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

	// FailedStartKlient is used when starting klient fails.
	FailedStartKlient = fmt.Sprintf(
		"Error: Failed to start the %s within the expected time.\n", config.KlientName,
	)

	// FailedStopKlient is used when stopping klient fails.
	FailedStopKlient = fmt.Sprintf(
		"Error: Failed to stop the %s within the expected time.\n", config.KlientName,
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
)
