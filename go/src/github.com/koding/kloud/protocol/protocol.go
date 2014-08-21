package protocol

import (
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
)

// Limiter checks before any other interface such as controller or builder is
// executed. If the Limit method returns an error the preceeding action is not
// executed. Limiter is usefull if you want have throttling or quota checking
// based on certain criterias.
type Limiter interface {
	Limit(opts *Machine, method string) error
}

// Builder creates and provision a single image or machine for a given Provider.
type Builder interface {
	// Build the machine and creates an artifact that can be pass to other
	// methods
	Build(*Machine) (*Artifact, error)

	// Cancel is called if there is an error in build process. This is helpful
	// to cleanup the build process and leftovers.
	Cancel(*Machine) error
}

// Provider manages a machine, it's start/stop/destroy/restart a machine.
type Controller interface {
	// Start starts the machine
	Start(*Machine) (*Artifact, error)

	// Stop stops the machine
	Stop(*Machine) error

	// Restart restarts the machine
	Restart(*Machine) error

	// Destroy destroys the machine
	Destroy(*Machine) error

	// Info returns full information about a single machine
	Info(*Machine) (*InfoArtifact, error)
}

// Machine is used as a context and data source for the appropriate interfaces
// provided by the Kloud package. A machine is gathered by the Storage
// interface.
type Machine struct {
	// MachineId defines a unique ID in which the build informations are
	// fetched from. MachineId is used to gather the Username, ImageName,
	// InstanceName etc.. For example it could be a mongodb object id that
	// would point to a document that carries those informations or a key for a
	// key/value storage.
	MachineId string

	// Provider defines the provider in which the data is used be
	Provider string

	// Builder contains information about how to build the data, like Username,
	// ImageName, InstanceName, Region, SSH KeyPair informations, etc...
	Builder map[string]interface{}

	// Credential contains information for accessing third party provider services
	Credential map[string]interface{}

	// Eventer pushes the latest events to the eventer hub. Anyone can listen
	// afterwards from the eventer hub.
	Eventer eventer.Eventer

	// State defines the machines current state
	State machinestate.State
}

// If available a key pair with the given public key and name should be
// deployed to the machine, the corresponding PrivateKey should be returned
// in the ProviderArtifact. Some providers such as Amazon creates
// publicKey's on the fly and generates the privateKey themself. The
// Deployer interface is then executed (only if the necessary privateKey is
// passed)
type ProviderDeploy struct {
	PublicKey  string `structure:"publicKey"`
	PrivateKey string `structure:"privateKey"`
	KeyName    string `structure:"keyName"`
	Username   string `structure:"username"`
}

// Artifact should be returned from a Build method. It contains data
// that is needed in other interfaces
type Artifact struct {
	// InstanceName should define the name/hostname of the created machine. It
	// should be equal to the InstanceName that was passed via MachineOptions.
	InstanceName string

	// InstanceId should define a unique ID that defined the created machine.
	// It's different than the machineID and is usually an unique id which is
	// given by the third-party provider, for example DigitalOcean returns a
	// droplet Id.
	InstanceId string

	// IpAddress defines the public ip address of the running machine.
	IpAddress string

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
