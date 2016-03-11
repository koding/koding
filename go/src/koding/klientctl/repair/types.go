package repair

type Repairer interface {
	// Status returns whether or not this repairer is ok via the returned error.
	// If a repairer returns an error, it needs to be able to handle Fixing (or failing)
	// the given issue.
	Status() error

	// Repair actually runs the recovery/repair process.
	Repair() error

	// String is a method for helping to identify the underlying Repair struct
	// implementing this interface. Mainly used to log errors for the failing
	// Repairer.
	String() string
}
