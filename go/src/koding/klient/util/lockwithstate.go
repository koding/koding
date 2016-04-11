package util

import "sync"

// MutexWithState tracks the locked/unlocked state, allowing the user to check
// if the mutext is locked without locking. The purpose of this is to potentially
// change behavior if the mutext is locked.
//
// Note that the implemented behavior of IsLocked is handled before and after lock
// and unlock respectively, meaning the value may "race" behind (albeit threadsafely)
// the real locked/unlocked status.
type MutexWithState struct {
	isLocked      bool
	isLockedMutex *sync.Mutex
	mutex         *sync.Mutex
}

func NewMutexWithState() *MutexWithState {
	return &MutexWithState{
		isLockedMutex: &sync.Mutex{},
		mutex:         &sync.Mutex{},
	}
}

// IsLocked returns whether this Mutex is currently locked.
func (l *MutexWithState) IsLocked() bool {
	l.isLockedMutex.Lock()
	defer l.isLockedMutex.Unlock()
	return l.isLocked
}

func (l *MutexWithState) Lock() {
	l.isLockedMutex.Lock()
	l.isLocked = true
	l.isLockedMutex.Unlock()

	l.mutex.Lock()
}

func (l *MutexWithState) Unlock() {
	l.mutex.Unlock()

	l.isLockedMutex.Lock()
	l.isLocked = false
	l.isLockedMutex.Unlock()
}
