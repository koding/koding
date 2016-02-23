package repair

type Repairer interface {
	// Status returns whether or not this repairer is needing to repair. The
	// originating error is also returned to track what the identified problem
	// is.
	Status() (bool, error)

	// Repair actually runs the recovery/repair process.
	Repair() error
}
