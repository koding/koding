package protocol

import "koding/kites/kloud/eventer"

type BuildOptions struct {
	// Username defines the username on behalf the machine is being build
	Username string

	// ImageName is used to build the machine based on this particular image
	ImageName string

	// InstanceName is used to change the machine name (usually hostname). If
	// it's empty a unique name will be used.
	InstanceName string

	// Eventer pushes the latest events to the build event.
	Eventer eventer.Eventer
}

// BuildResponse should be returned from a Build method
type BuildResponse struct {
	// InstanceName should define the name/hostname of the created machine. It
	// should be equal as InstanceName
	InstanceName string

	// InstanceId should define a unique ID that defined the created machine.
	InstanceId int

	// KiteId should container the id that is deployed inside the machine
	KiteId string

	// IpAddress is the
	IpAddress string
}

// Provider manages a machine. It is used to create and provision a single
// image or machine for a given Provider, to start/stop/destroy/restart a
// machine.
type Provider interface {
	// Prepare is responsible of configuring and initializing the builder and
	// validating the given configuration prior Build.
	Prepare(...interface{}) error

	// Build is creating a image and a machine.
	Build(*BuildOptions) (*BuildResponse, error)

	// Start starts the machine
	Start(...interface{}) error

	// Stop stops the machine
	Stop(...interface{}) error

	// Restart restarts the machine
	Restart(...interface{}) error

	// Destroy destroys the machine
	Destroy(...interface{}) error

	// Info returns full information about a single machine
	Info(...interface{}) (interface{}, error)
}
