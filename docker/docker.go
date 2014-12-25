// Package docker provides a layer on top of Docker's API via Kite handlers.
package docker

import (
	"bytes"
	"errors"
	"os"
	"strconv"
	"time"
	"unicode/utf8"

	dockerclient "github.com/koding/klient/Godeps/_workspace/src/github.com/fsouza/go-dockerclient"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
)

// Docker defines the main configuration. One instance is running as one Docker
// client, so multiple instances of a Docker struct can connect to multiple
// Docker Servers.
type Docker struct {
	client *dockerclient.Client
	log    kite.Logger
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
			Tty:   true,
			// AttachStdin:  true,
			// AttachStdout: true,
			// AttachStderr: true,
		},
	}

	container, err := d.client.CreateContainer(opts)
	if err != nil {
		return nil, err
	}

	return container.Name, nil
}

// Exec connects to an existing Container by spawning a new process and
// attaching to it.
func (d *Docker) Exec(r *kite.Request) (interface{}, error) {
	var params struct {
		// The ID of the container.
		ID string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if params.ID == "" {
		return nil, errors.New("missing arg: container is is empty")
	}

	createOpts := dockerclient.CreateExecOptions{
		Container: params.ID,
		Tty:       true,
		Cmd:       []string{"bash"},
		// we attach to anything, it's used in the same was as with `docker
		// exec`
		AttachStdout: true,
		AttachStderr: true,
		AttachStdin:  true,
	}

	// now we create a new Exec instance. It will return us an exec ID which
	// will be used to start the created exec instance
	d.log.Info("Creating exec instance")
	ex, err := d.client.CreateExec(createOpts)
	if err != nil {
		return nil, err
	}

	// testing ...
	stdoutBuffer := new(bytes.Buffer)
	stdinBuffer.WriteString(`ls\r`)

	opts := dockerclient.StartExecOptions{
		RawTerminal:  true,      // because we are creating containers with Tty:true
		OutputStream: os.Stdout, // if tty is enabled, stderr is included in output
		ErrorStream:  os.Stderr,
		InputStream:  stdinBuffer,
	}

	d.log.Info("Starting exec instance '%s'", ex.ID)
	if err := d.client.StartExec(ex.ID, opts); err != nil {
		return nil, err
	}

	time.Sleep(time.Second * 30)

	return nil, errors.New("not implemented yet.")
}

// Stop stops a running container
func (d *Docker) Stop(r *kite.Request) (interface{}, error) {
	var params struct {
		// The ID of the container.
		ID string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if params.ID == "" {
		return nil, errors.New("missing arg: container is is empty")
	}

	if err := d.client.StopContainer(params.ID, 0); err != nil {
		return nil, err
	}

	return true, nil
}

// Start starts a stopped container
func (d *Docker) Start(r *kite.Request) (interface{}, error) {
	var params struct {
		// The ID of the container.
		ID string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if params.ID == "" {
		return nil, errors.New("missing arg: container is is empty")
	}

	if err := d.client.StartContainer(params.ID, nil); err != nil {
		return nil, err
	}

	return true, nil
}

// RemoveContainer removes a container
func (d *Docker) RemoveContainer(r *kite.Request) (interface{}, error) {
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

func filterInvalidUTF8(buf []byte) []byte {
	i := 0
	j := 0
	for {
		r, l := utf8.DecodeRune(buf[i:])
		if l == 0 {
			break
		}
		if r < 0xD800 {
			if i != j {
				copy(buf[j:], buf[i:i+l])
			}
			j += l
		}
		i += l
	}
	return buf[:j]
}
