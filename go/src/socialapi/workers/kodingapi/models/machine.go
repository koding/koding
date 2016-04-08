// Package models holds generated struct for Machine.
package models

// import "github.com/cihangir/govalidator"
import "koding/db/models"

// Machine represents a registered Account's Machine Info
type Machine struct {
	Machine *models.Machine
	Status *models.MachineStatus
}

//
// // Machine represents a registered Account's Machine Info
// type Machine struct {
// 	// The unique identifier for a Machine
// 	ID int64 `json:"id,omitempty,string"`
// 	// Username is the user name of the machine
// 	Username string `json:"username"`
// 	// Owner return if the machine's username is owner or not.
// 	Owner bool `json:"owner,omitempty"`
// 	// State is the current status of the machine.
// 	State string `json:"state,omitempty"`
// }

// NewMachine creates a new Machine struct with default values
func NewMachine() *Machine {
	return &Machine{}
}

// Validate validates the Machine struct
func (m *Machine) Validate() error {
	return nil
	// return govalidator.NewMulti(govalidator.MaxLength(m.State, 30),
		// govalidator.MaxLength(m.Username, 20),
		// govalidator.Min(float64(m.ID), 1.000000),
		// govalidator.MinLength(m.Username, 4)).Validate()
}
//
