// Package docker provides a layer on top of Docker's API via Kite handlers.
package docker

import (
	"errors"
	"strconv"
	"time"

	dockerclient "github.com/koding/klient/Godeps/_workspace/src/github.com/fsouza/go-dockerclient"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
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

// Build builds a new container image from a public Docker path or from a
// given Dockerfile
func (d *Docker) Build(r *kite.Request) (interface{}, error) {
	return nil, errors.New("build is not implemented yet.")
}

// Create creates a new container
func (d *Docker) Create(r *kite.Request) (interface{}, error) {
	var params struct {
		// Custom Container name
		Name string

		// Image name
		Image string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if params.Image == "" {
		return nil, errors.New("missing arg: image is empty")
	}

	// generate new name if name is missing
	if params.Name == "" {
		params.Name = r.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	}

	opts := dockerclient.CreateContainerOptions{
		Name: params.Name,
		Config: &dockerclient.Config{
			Image: params.Image,
		},
	}

	container, err := d.client.CreateContainer(opts)
	if err != nil {
		return nil, err
	}

	return container.Name, nil
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

// RemoveContainer removes a container
func (d *Docker) RemoveContainer(r *kite.Request) (interface{}, error) {
	// we can remove either by name or by id
	var params struct {
		// The ID of the container.
		ID string

		// A flag that indicates whether Docker should remove the volumes
		// associated to the container.
		RemoveVolumes bool

		// A flag that indicates whether Docker should remove the container
		// even if it is currently running.
		Force bool
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if params.ID == "" {
		return nil, errors.New("missing arg: container is is empty")
	}

	opts := dockerclient.RemoveContainerOptions{
		ID: params.ID,
	}

	if err := d.client.RemoveContainer(opts); err != nil {
		return nil, err
	}

	return true, nil
}

// RemoveImage removes an existing image.
func (d *Docker) RemoveImage(r *kite.Request) (interface{}, error) {
	// we can remove either by name or by id
	var params struct {
		// Container name
		Name string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if params.Name == "" {
		return nil, errors.New("missing arg: name is empty")
	}

	if err := d.client.RemoveImage(params.Name); err != nil {
		return nil, err
	}

	return true, nil
}

// List lists all available containers
func (d *Docker) List(r *kite.Request) (interface{}, error) {
	filter := dockerclient.ListContainersOptions{
		All: true,
	}

	return d.client.ListContainers(filter)
}
