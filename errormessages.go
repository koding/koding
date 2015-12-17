package main

import "fmt"

const (
	retryOrContactSupport        = "Please try again, or contact support@koding.com"
	retryNewCodeOrContactSupport = `Please go back to Koding to get a new code and try again, or contact support@koding.com`
)

var (
	// InternalRetryError is typically used when the circumstances that caused the error
	// are implementation details only and cannot be told to the user, and that they
	// can't do anything to correct the error.
	//
	// The only thing left is to .. retry, or possibly report to support@koding.com?
	GenericInternalError = fmt.Sprintf(
		"Error: Encountered an internal error.\n%s", retryOrContactSupport,
	)

	GenericInternalErrorRetry = fmt.Sprintf(
		"Error: Encountered an internal error.\n%s", retryNewCodeOrContactSupport,
	)

	FailedInstallingKlient = fmt.Sprintf(
		"Error: Unable to install the %s.\n%s", KlientName, retryNewCodeOrContactSupport,
	)

	FailedDownloadingKlient = fmt.Sprintf(
		"Error: Unable to download the %s binary.\n%s",
		KlientName, retryNewCodeOrContactSupport,
	)

	FailedRegisteringKlient = fmt.Sprintf(
		"Error: Unable to authenticate %s to koding.com.\n%s",
		Name, retryNewCodeOrContactSupport,
	)

	FailedVerifyingInstall = fmt.Sprintf(
		"Error: Unable to verify the installation of %s.\n%s",
		Name, retryNewCodeOrContactSupport,
	)

	FailedStartKlient = fmt.Sprintf(
		"Error: Failed to start the %s within the expected time.\n%s", KlientName, retryOrContactSupport,
	)

	FailedStopKlient = fmt.Sprintf(
		"Error: Failed to stop the %s within the expected time.\n%s", KlientName, retryOrContactSupport,
	)
)
