package dnsstorage

// Domain represents a machines domain necessary information
type Domain struct {
	// Username defines a the owner of the machine
	Username string

	// MachineId defines the ID of the respective machine. Each domain is bound
	// to a single machine.
	MachineId string

	// Name is the domain name, such as "arslan.koding.io" or
	// "fatih.arslan.koding.io"
	Name string
}

// Storage is responsible of managing domain specific storage actions
type Storage interface {
	// Add adds a new domain
	Add(*Domain) error

	// Delete deletes the DomainDocument with the given domain name
	Delete(name string) error

	// UpdateMachine updates the machine relationship for the given domain name
	// with the given new machine id. Machine ID can be empty
	UpdateMachine(name, machine string) error

	// Get returns the domain information with the given domain name
	Get(name string) (*Domain, error)

	// GetByMachine returns the domains that belongs to the given machine
	GetByMachine(machine string) ([]*Domain, error)
}
