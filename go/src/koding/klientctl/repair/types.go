package repair

type Repairer interface {
	// Status returns whether or not this repairer is ok. The
	// originating error is also returned to track what the identified problem
	// is.
	Status() (bool, error)

	// Repair actually runs the recovery/repair process.
	Repair() error

	// String is a method for helping to identify the underlying Repair struct
	// implementing this interface. Mainly used to log errors for the failing
	// Repairer.
	String() string
}
