// Package sem provides Semaphores.
// Semaphores are a very general synchronization mechanism that can be used to
// implement mutexes, limit access to multiple resources, solve the readers-
// writers problem, etc.
package sem

type semaphore chan struct{}

//NewSemaphore creates a new Semaphores
func New(concurrency int64) semaphore {
	s := make(semaphore, concurrency)

	var i int64

	for i = 0; i < concurrency; i++ {
		s.Unlock()
	}

	return s
}

// Lock obtains one item from capacity
func (s semaphore) Lock() {
	<-s
}

// Lock add one item into capacity
func (s semaphore) Unlock() {
	s <- struct{}{}
}
