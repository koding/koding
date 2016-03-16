package repair

type Repairer interface {
	// Status returns whether or not this repairer is ok via the bool value. Status
	// should only return a not-okay bool if it can fix the issue!
	//
	// If Status returns an error, it means a requirement for asserting the status
	// has not been met. For example, if a Repairer is responsible for checking
	// Klient's connection, klient must be running for that Status check to work.
	// Status *should* return an error in that case. *Only* return an error for
	// failed requirements.
	//
	// If the status methods requirements are met, but something returns an error
	// it is not able to fix (TokenNotValid vs TokenExpired, for example),
	// Status should return `okay` and `nil error`.
	Status() (bool, error)

	// Repair actually runs the recovery/repair process.
	Repair() error

	// String is a method for helping to identify the underlying Repair struct
	// implementing this interface. Mainly used to log errors for the failing
	// Repairer.
	String() string
}
