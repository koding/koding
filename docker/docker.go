// Package docker provides a layer on top of Docker's API via Kite handlers.
package docker

import (
	"errors"

	"github.com/koding/kite"
	"github.com/samalba/dockerclient"
)

// Docker defines the main configuration. One instance is running as one Docker
// client, so multiple instances of a Docker struct can connect to multiple
// Docker Servers. After creating a new Docker struct, it'll be able to manage
// Docker containers. A usual working lifecyle is:
// 1. Build a Docker image
// 2. Create a new Docker container from that image
// 3. Start this container
// 4. Connect and open a terminal instance to it (optional)
// 5. Stop the container
// 6. Remove the container
// 7. Destroy the image
type Docker struct {
	client *dockerclient.DockerClient
}

// New connects to a Docker Deamon specified with the given URL. It can be a
// TCP address or a UNIX socket.
func New(url string) *Docker {
	// the error is returned only when the passed URL is not parsable via
	// url.Parse, so we can safely neglect it
	client, _ := dockerclient.NewDockerClient(url, nil)
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
