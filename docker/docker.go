// Package docker provides a layer on top of Docker's API via Kite handlers.
package docker

import (
	"errors"

	"github.com/koding/kite"
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
type Docker struct{}

// TODO:
// 1. Docker Deamon needs to be run in TCP Mode. If UNIX sockets are used we
// need to setup the client so it has access to the `docker` group which
// maintains the the socket. So initiallty TCP is a good start.
// 2. TCP mode is enabled by adding "-H tcp://bind-ip:port" to
// /etc/default/docker or DOCKER_OPTS
// 3. But only authenticated Client should access it over TCP, so we need to
// generate TLS cert keys and let both the Deamon and Client use it.
// 4. The boot2docker guys are using this package:
// https://github.com/SvenDowideit/generate_cert for it which we can also use.
// 5. Here is also some information on how to start the Docker Deamon securely
// https://docs.docker.com/articles/https/
func New() *Docker {
	return &Docker{}
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
