package protocol

import (
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud/machinestate"
)

// Provider manages a machine. It is used to create and provision a single
// image or machine for a given Provider, to start/stop/destroy/restart a
// machine.
type Provider interface {
	// Build is creating a image and a machine.
	Build(*MachineOptions) (*ProviderArtifact, error)

	// Start starts the machine
	Start(*MachineOptions) (*ProviderArtifact, error)

	// Stop stops the machine
	Stop(*MachineOptions) error

	// Restart restarts the machine
	Restart(*MachineOptions) error

	// Destroy destroys the machine
	Destroy(*MachineOptions) error

	// Info returns full information about a single machine
	Info(*MachineOptions) (*InfoArtifact, error)

	// Name returns the underlying provider type
	Name() string
}

// contains all necessary informations.
type MachineOptions struct {
	// MachineId defines a unique ID in which the build informations are
	// fetched from. MachineId is used to gather the Username, ImageName,
	// InstanceName etc.. For example it could be a mongodb object id that
	// would point to a document that carries those informations or a key for a
	// key/value storage.
	MachineId string

	// Username defines the username on behalf the machine is being build.
	Username string

	// ImageName is used to build the machine based on this particular image.
	ImageName string

	// InstanceName is used to change the machine name (usually hostname). If
	// it's empty a unique name will be used.
	InstanceName string

	// Builder contains information about how to build the data
	Builder map[string]interface{}

	// Credential contains information for accessing third party provider services
	Credential map[string]interface{}

	// Eventer pushes the latest events to the build event.
	Eventer eventer.Eventer
}

// BuildArtifact should be returned from a Build method.
type ProviderArtifact struct {
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
}

// InfoArtifact should be returned from a Info method.
type InfoArtifact struct {
	// State defines the state of the machine
	State machinestate.State

	// Name defines the name of the machine.
	Name string
}

// DeployArtifact should be returned from a Deploy Method
type DeployArtifact struct {
	KiteQuery string
}
