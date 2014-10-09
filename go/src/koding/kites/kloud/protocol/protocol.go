package protocol

import (
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
)

// Provider manages a machine, it's start/stop/destroy/restart a machine.
type Provider interface {
	// Build the machine and creates an artifact that can be pass to other
	// methods
	Build(*Machine) (*Artifact, error)

	// Start starts the machine
	Start(*Machine) (*Artifact, error)

	// Stop stops the machine
	Stop(*Machine) error

	// Restart restarts the machine
	Restart(*Machine) error

	// Reinit destroys and builds the machine, basically re initializes
	// the machine to a new and clean state.
	Reinit(*Machine) (*Artifact, error)

	// Destroy destroys the machine
	Destroy(*Machine) error

	// Resize the machine and creates an artifact that can be pass to other
	// methods
	Resize(*Machine) (*Artifact, error)

	// Info returns full information about a single machine
	Info(*Machine) (*InfoArtifact, error)
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

// Record represents a single record for a given domain
type Record struct {
	Name string
	IP   string
	TTL  int
}

// Domain represents a machines domain necessary information
type Domain struct {
	// OriginId defines a unique ID that represents an ownership. There might
	// be several domains each with the same OriginId, which means they all
	// belong to a user.
	OriginId string

	// MachineId defines the ID of the respective machine. Each domain is bound
	// to a single machine.
	MachineId string

	// Name is the domain name, such as "arslan.koding.io" or
	// "fatih.arslan.koding.io"
	Name string
}

// Machine is used as a data source for the appropriate interfaces
// provided by the Kloud package. A context is gathered by the Storage
// interface.
type Machine struct {
	// Id defines a unique ID in which the build informations are fetched from.
	// Is is used to gather the Username, ImageName, InstanceName etc..  For
	// example it could be a mongodb object id that would point to a document
	// that carries those informations or a key for a key/value storage.
	Id string

	// Username defines the owner of the machine
	Username string

	// Provider defines the provider in which the data is used to be operated.
	Provider string

	// Builder contains information about how to build the data, like
	// ImageName, InstanceName, Region, SSH KeyPair informations, etc...
	Builder map[string]interface{}

	// Credential contains information for accessing third party provider services
	Credential map[string]interface{}

	// Domain contains domain specific information of the machine
	Domain Domain

	// IpAddress defines the public IP address of that given machine
	IpAddress string

	// QueryString defines the query needed for finding the Klient kite inside
	// the machine
	QueryString string

	// Eventer pushes the latest events to the eventer hub. Anyone can listen
	// afterwards from the eventer hub.
	Eventer eventer.Eventer

	// State defines the machines current state
	State machinestate.State
}

// Artifact should be returned from a Build method. It contains data
// that is needed in other interfaces
type Artifact struct {
	// Machine Id defines the source of the build that caused this artifact to
	// be created. It should be equal to the MachineId that was passed via
	// MachineOptions
	MachineId string

	// InstanceName should define the name/hostname of the created machine. It
	// should be equal to the InstanceName that was passed via MachineOptions.
	InstanceName string

	// InstanceId should define a unique ID that defined the created machine.
	// It's different than the machineID and is usually an unique id which is
	// given by the third-party provider, for example DigitalOcean returns a
	// droplet Id, AWS returns an instance id, etc..
	InstanceId string

	// IpAddress defines the public ip address of the running machine.
	IpAddress string

	// DomainName defines the current domain record that is bound to the given
	// IpAddress
	DomainName string

	// Username defines the username to which the machine belongs.
	Username string

	// PrivateKey defines a private SSH key added to the machine. It's only
	// returned if the SSHKeyName and SSHPublicKey is defined in MachineOptions
	SSHPrivateKey string
	SSHUsername   string

	// KiteQuery is needed to find it via Kontrol
	KiteQuery string
}

// InfoArtifact should be returned from a Info method.
type InfoArtifact struct {
	// State defines the state of the machine
	State machinestate.State

	// Name defines the name of the machine.
	Name string
}
