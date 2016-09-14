package stack

var ErrLockAcquired = NewError(ErrMachineIsLocked)

// Locker is a distributed lock that locks with the specific id and unlocks
// again with the given id.
type Locker interface {
	// Lock should lock with the given Id. If there is a lock already it should
	// return the ErrLockAcquired error.
	Lock(id string) error

	// Unlock unlocks the lock with the given id.
	Unlock(id string)
}
