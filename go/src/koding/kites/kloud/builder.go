package main

// Builder is used to create a single image or machine.
type Builder interface {
	Build() error
}

// Provisioner is used to provision a given image
type Provisioner interface {
	Provision() error
}

// Controller manages a machine
type Controller interface {
	Start() error
	Stop() error
	Restart() error
	Destroy() error
}
