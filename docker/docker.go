// Package docker provides a layer on top of Docker's API via Kite handlers.
package docker

import (
	"errors"

	dockerclient "github.com/fsouza/go-dockerclient"
	"github.com/koding/kite"
)

// Docker defines the main configuration. One instance is running as one Docker
// client, so multiple instances of a Docker struct can connect to multiple
// Docker Servers.
type Docker struct {
	client *dockerclient.Client
}

// New connects to a Docker Deamon specified with the given URL. It can be a
// TCP address or a UNIX socket.
func New(url string) *Docker {
	// the error is returned only when the passed URL is not parsable via
	// url.Parse, so we can safely neglect it
	client, _ := dockerclient.NewClient(url)
	return &Docker{
		client: client,
	}
}

// Build builds a new container image from a public Docker path or froma a
// given Dockerfile
func (d *Docker) Build(r *kite.Request) (interface{}, error) {
	return nil, errors.New("not implemented yet.")
}

// Create creates a new container
func (d *Docker) Create(r *kite.Request) (interface{}, error) {
	return nil, errors.New("not implemented yet.")
}

// Connects connects to an existing Container by spawning a new process and
// attaching to it.
func (d *Docker) Connect(r *kite.Request) (interface{}, error) {
	return nil, errors.New("not implemented yet.")
}

// Stop stops a running container
func (d *Docker) Stop(r *kite.Request) (interface{}, error) {
	return nil, errors.New("not implemented yet.")
}

// Start starts a stopped container
func (d *Docker) Start(r *kite.Request) (interface{}, error) {
	return nil, errors.New("not implemented yet.")
}

// Kill kills and delete a container
func (d *Docker) Kill(r *kite.Request) (interface{}, error) {
	return nil, errors.New("not implemented yet.")
}

// Destroy destroys and removes an image.
func (d *Docker) Destroy(r *kite.Request) (interface{}, error) {
	return nil, errors.New("not implemented yet.")
}

// List lists all available containers
func (d *Docker) List(r *kite.Request) (interface{}, error) {
	return nil, errors.New("not implemented yet.")
}
