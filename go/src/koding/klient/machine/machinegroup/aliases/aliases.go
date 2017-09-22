package aliases

import (
	"math/rand"
	"strconv"
	"sync"
	"time"

	"koding/klient/machine"
)

func init() {
	// initialize pseudo random number generator.
	rand.Seed(time.Now().UnixNano())
}

// colors defines the available colors for aliases. The first letter of each
// color name must be unique across the slice.
var colors = [...]string{
	"aqua",
	"black",
	"fuchsia",
	"green",
	"lime",
	"maroon",
	"navy",
	"olive",
	"purple",
	"red",
	"silver",
	"teal",
	"white",
	"yellow",
}

// fruits defines the available fruits for aliases. The first letter of each
// fruit name must be unique across the slice.
var fruits = [...]string{
	"apple",
	"banana",
	"coconut",
	"date",
	"fig",
	"grape",
	"jackfruit",
	"kiwi",
	"lemon",
	"mango",
	"nectarine",
	"orange",
	"peach",
	"quince",
	"raisin",
	"squash",
	"tomato",
	"watermelon",
}

// Aliases store alternative names for the group of machines.
type Aliases struct {
	mu sync.RWMutex
	m  map[machine.ID]string
}

// New creates an empty Aliases object.
func New() *Aliases {
	return &Aliases{
		m: make(map[machine.ID]string),
	}
}

// Add binds custom alias to provided machine.
func (a *Aliases) Add(id machine.ID, alias string) error {
	a.mu.Lock()
	defer a.mu.Unlock()
	a.m[id] = alias

	return nil
}

// Create generates a new alias for provided machine ID. If alias already
// exists, it will not be regenerated.
func (a *Aliases) Create(id machine.ID) (string, error) {
	a.mu.Lock()
	defer a.mu.Unlock()

	if alias, ok := a.m[id]; ok {
		return alias, nil
	}

	// Get current aliases.
	current := make(map[string]struct{}, len(a.m))
	for _, alias := range a.m {
		current[alias] = struct{}{}
	}

	// Generate new alias.
	for i := 0; ; i++ {
		alias := colors[rand.Intn(len(colors))] + "_" + fruits[rand.Intn(len(fruits))]

		if suffix := i / (len(colors) * len(fruits)); suffix > 0 {
			alias += strconv.Itoa(suffix)
		}

		if _, ok := current[alias]; !ok {
			a.m[id] = alias
			return alias, nil
		}
	}
}

// Drop removes alias which is bound to provided machine ID.
func (a *Aliases) Drop(id machine.ID) error {
	a.mu.Lock()
	defer a.mu.Unlock()
	delete(a.m, id)

	return nil
}

// MachineID checks if there is a machine ID that is bound to provided alias.
// If yes, the machine ID is returned. machine.ErrMachineNotFound is returned
// if there is no machine ID with provided alias.
//
// TODO: Add support for shortcuts like rb1 == red_banana1 etc.
func (a *Aliases) MachineID(alias string) (machine.ID, error) {
	a.mu.RLock()
	defer a.mu.RUnlock()
	for id, a := range a.m {
		// provided alias can be the machine ID itself.
		if machine.ID(alias) == id || alias == a {
			return id, nil
		}
	}

	return "", machine.ErrMachineNotFound
}

// Registered returns all machines that are stored in this object.
func (a *Aliases) Registered() machine.IDSlice {
	a.mu.RLock()
	defer a.mu.RUnlock()

	registered := make(machine.IDSlice, 0, len(a.m))
	for id := range a.m {
		registered = append(registered, id)
	}

	return registered
}

// all returns all stored aliases.
func (a *Aliases) all() map[machine.ID]string {
	all := make(map[machine.ID]string)

	a.mu.RLock()
	defer a.mu.RUnlock()
	for id, alias := range a.m {
		all[id] = alias
	}

	return all
}
