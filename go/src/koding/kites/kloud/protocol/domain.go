package protocol

// Record represents a single record for a given domain
type Record struct {
	Name string
	IP   string
	TTL  int
}

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

// Domainer is responsible of managing DNS records
type Domainer interface {
	// Create creates a new domain record with the given name to the new IP
	Create(name, newIP string) error

	// Delete deletes the given domain name which was associated to the old IP
	Delete(name, oldIP string) error

	// Update updates the given domain name which was associated to the old IP
	// with the new IP
	Update(name, oldIP, newIP string) error

	// Rename renames the given old domain name with the new domain name for
	// the given IP
	Rename(oldName, newName, currentIp string) error

	// Get returns a domain record for the given domain name
	Get(name string) (*Record, error)

	// HostedZone returns the top level domain on which the domains are going
	// to be handled. Such as dev.koding.io or koding.io
	HostedZone() string

	// Validate validates if the given domain name is valid
	Validate(domainName, username string) error
}

// DomainStorage is responsible of managing domain specific storage actions
type DomainStorage interface {
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
