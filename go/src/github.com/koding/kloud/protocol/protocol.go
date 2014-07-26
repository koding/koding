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
	Limit(opts *MachineOptions, method string) error
}

// Builder creates and provision a single image or machine for a given Provider.
type Builder interface {
	Build(*MachineOptions) (*Artifact, error)
}

// Cleaner clean up necessary tasks after a build.
type Cleaner interface {
	Cleanup(*Artifact) error
}

// Provider manages a machine, it's start/stop/destroy/restart a machine.
type Controller interface {
	// Start starts the machine
	Start(*MachineOptions) (*Artifact, error)

	// Stop stops the machine
	Stop(*MachineOptions) error

	// Restart restarts the machine
	Restart(*MachineOptions) error

	// Destroy destroys the machine
	Destroy(*MachineOptions) error

	// Info returns full information about a single machine
	Info(*MachineOptions) (*InfoArtifact, error)
}

// contains all necessary informations.
type MachineOptions struct {
	// MachineId defines a unique ID in which the build informations are
	// fetched from. MachineId is used to gather the Username, ImageName,
	// InstanceName etc.. For example it could be a mongodb object id that
	// would point to a document that carries those informations or a key for a
	// key/value storage.
	MachineId string

	// Builder contains information about how to build the data, like Username,
	// ImageName, InstanceName, Region, SSH KeyPair informations, etc...
	Builder map[string]interface{}

	// Credential contains information for accessing third party provider services
	Credential map[string]interface{}

	// Eventer pushes the latest events to the build event.
	Eventer eventer.Eventer
}

// If available a key pair with the given public key and name should be
// deployed to the machine, the corresponding PrivateKey should be returned
// in the ProviderArtifact. Some providers such as Amazon creates
// publicKey's on the fly and generates the privateKey themself. The
// Deployer interface is then executed (only if the necessary privateKey is
// passed)
type ProviderDeploy struct {
	PublicKey  string
	PrivateKey string
	KeyName    string
	Username   string
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

	// Storage provides a simple caching/state mechanism between calls
	Storage
}

// InfoArtifact should be returned from a Info method.
type InfoArtifact struct {
	// State defines the state of the machine
	State machinestate.State

	// Name defines the name of the machine.
	Name string
}

func NewArtifact() *Artifact {
	a := &Artifact{}
	a.Storage = NewMapStorage()
	return a
}
