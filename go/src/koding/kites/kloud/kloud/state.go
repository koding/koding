package kloud

import "sync"

type Stater interface {
	// Add adds or updates the state for the given id
	Add(string, MachineState)

	// Delete deletes the given id
	Delete(string)

	// Get returns the state for the given id
	Get(string) MachineState
}

type States struct {
	s map[string]MachineState
	sync.Mutex
}

type MachineState int

const (
	NotInitialized MachineState = iota + 1 // Machine instance does not exists
	Building                               // Build started machine instance creating...
	Starting                               // Machine is booting...
	Running                                // Machine is physically running
	Stopping                               // Machine is turning off...
	Stopped                                // Machine is turned off
	Rebooting                              // Machine is rebooting...
	Terminating                            // Machine is getting destroyed...
	Terminated                             // Machine is destroyed, not exists anymore
)

func NewStater() Stater {
	return &States{
		s: make(map[string]MachineState),
	}
}

func (s *States) Add(id string, state MachineState) {
	s.Lock()
	defer s.Unlock()

	s.s[id] = state
}

func (s *States) Delete(id string) {
	s.Lock()
	defer s.Unlock()

	delete(s.s, id)
}

func (s *States) Get(id string) MachineState {
	s.Lock()
	defer s.Unlock()

	return s.s[id]
}
