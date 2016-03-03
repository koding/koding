package kiteerrortypes

const (
	//
	// Kite error types not generated from Klient:
	// (Leave cases as is)
	//

	AuthenticationError = "authenticationError"

	//
	// Kite error types generated from klient:
	//

	MachineNotFound           = "MachineNotFound"
	MachineUnreachable        = "MachineUnreachable"
	AuthErrTokenIsExpired     = "AuthErrTokenIsExpired"
	AuthErrTokenIsNotValidYet = "AuthErrTokenIsNotValidYet"
	MissingArgument           = "MissingArgument"

	// DialingFailed is the kite.Error.Type used for errors encountered when
	// dialing the remote.
	DialingFailed = "dialing failed"

	// MountNotFound is the kite.Error.Type used for errors encountered when
	// the mount name given cannot be found.
	MountNotFound = "mount not found"

	// SystemUnmountFailed is the Kite Error Type used when either the unmounter
	// fails, or generic (non-instanced) unmount fails.
	SystemUnmountFailed = "system-unmount-failed"
)
