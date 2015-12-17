package main

import "fmt"

const (
	retryOrContactSupport        = "Please try again, or contact support@koding.com"
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
)
