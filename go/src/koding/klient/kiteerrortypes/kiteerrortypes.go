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
	MountNotFound             = "MountNotFound"
	AuthErrTokenIsExpired     = "AuthErrTokenIsExpired"
	AuthErrTokenIsNotValidYet = "AuthErrTokenIsNotValidYet"
)
