package repair

type Repairer interface {
	// Name is a method for helping to identify the underlying Repair struct
	// implementing this interface. Mainly used to log errors for the failing
	// Repairer.
	Name() string

	// Description is a user facing description of this repairer. Mainly used
	// to describe the generic Repairer to the user, so they know that we found a
	// problem with X, and are trying to fix it.
	Description() string

	// Status returns whether or not this repairer is ok. The
	// originating error is also returned to track what the identified problem
	// is.
	Status() (bool, error)

	// Repair actually runs the recovery/repair process.
	Repair() error
}
