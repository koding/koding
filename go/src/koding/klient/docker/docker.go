// Package docker provides a layer on top of Docker's API via Kite handlers.
package docker

import (
	"errors"
	"fmt"
	"io"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	dockerclient "github.com/fsouza/go-dockerclient"
	"github.com/koding/kite"
	"github.com/rogpeppe/go-charset/charset"
	_ "github.com/rogpeppe/go-charset/data"
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
func New(url string, log kite.Logger) *Docker {
	// the error is returned only when the passed URL is not parsable via
	// url.Parse, so we can safely neglect it
	client, _ := dockerclient.NewClient(url)
	return &Docker{
		client: client,
		log:    log,
	}
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
			// the following Attach fields need to be set so we can open a TTY
			// instace via the Connect method.
			AttachStdin:  true,
			AttachStdout: true,
			AttachStderr: true,
		},
	}

	container, err := d.client.CreateContainer(opts)
	if err != nil {
		return nil, err
	}

	return container.Name, nil
}

// Connect connects to an existing Container by spawning a new process and
// attaching to it.
func (d *Docker) Connect(r *kite.Request) (interface{}, error) {
	var params struct {
		// The ID of the container. This needs to be created and started before
		// we can use Connect.
		ID string

		// Cmd contains the command which is executed and passed to the docker
		// exec api. If empty "bash" is used.
		Cmd string

		SizeX, SizeY int

		Remote Remote
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if params.ID == "" {
		return nil, errors.New("missing arg: container ID is empty")
	}

	cmd := []string{"bash"}
	if params.Cmd != "" {
		cmd = strings.Fields(params.Cmd)
	}

	createOpts := dockerclient.CreateExecOptions{
		Container: params.ID,
		Tty:       true,
		Cmd:       cmd,
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

	// these pipes are important as we are acting as a proxy between the
	// Browser (client side) and Docker Deamon. For example, every input coming
	// from the client side is being written into inWritePipe and this input is
	// then read by docker exec via the inReadPipe.
	inReadPipe, inWritePipe := io.Pipe()
	outReadPipe, outWritePipe := io.Pipe()

	opts := dockerclient.StartExecOptions{
		Detach:       false,
		Tty:          true,
		OutputStream: outWritePipe,
		ErrorStream:  outWritePipe, // this is ok, that's how tty works
		InputStream:  inReadPipe,
	}

	// Control characters needs to be in ISO-8859 charset, so be sure that
	// UTF-8 writes are translated to this charset, for more info:
	// http://en.wikipedia.org/wiki/Control_character
	controlSequence, err := charset.NewWriter("ISO-8859-1", inWritePipe)
	if err != nil {
		return nil, err
	}

	errCh := make(chan error)
	closeCh := make(chan bool)

	server := &Server{
		Session:         ex.ID,
		remote:          params.Remote,
		out:             outReadPipe,
		in:              inWritePipe,
		controlSequence: controlSequence,
		closeChan:       closeCh,
		client:          d.client,
	}

	go func() {
		d.log.Info("Starting exec instance '%s'", ex.ID)
		err := d.client.StartExec(ex.ID, opts)
		errCh <- err

		// call the remote function that we ended the session
		server.remote.SessionEnded.Call()
	}()

	go func() {
		select {
		case err := <-errCh:
			if err != nil {
				d.log.Error("startExec error: ", err)
			}
		case <-closeCh:
			// once we close them the underlying hijack process in docker
			// client package will end too, which will close the underlying
			// connection once it's finished/returned.
			inReadPipe.CloseWithError(errors.New("user closed the session"))
			inWritePipe.CloseWithError(errors.New("user closed the session"))

			outReadPipe.CloseWithError(errors.New("user closed the session"))
			outWritePipe.CloseWithError(errors.New("user closed the session"))
		}
	}()

	var once sync.Once

	// Read the STDOUT from shell process and send to the connected client.
	// https://github.com/koding/koding/commit/50cbd3609af93334150f7951dae49a23f71078f6
	go func() {
		buf := make([]byte, (1<<12)-utf8.UTFMax, 1<<12)
		for {
			n, err := server.out.Read(buf)
			for n < cap(buf)-1 {
				r, _ := utf8.DecodeLastRune(buf[:n])
				if r != utf8.RuneError {
					break
				}
				server.out.Read(buf[n : n+1])
				n++
			}

			// we need to set it for the first time. Because "StartExec" is
			// called in a goroutine and it's blocking there is now way we know
			// when it's ready. Therefore we set the size only once when get an
			// output. After that the client side is setting the TTY size with
			// the Server.SetSize method, that is called everytime the client
			// side sends a size command to us.
			once.Do(func() {
				// Y is  height, X is width
				err = d.client.ResizeExecTTY(ex.ID, int(params.SizeY), int(params.SizeX))
				if err != nil {
					fmt.Println("error resizing", err)
				}
			})

			server.remote.Output.Call(string(filterInvalidUTF8(buf[:n])))
			if err != nil {
				break
			}
		}
		d.log.Debug("Breaking out of for loop")
	}()

	d.log.Debug("Returning server")
	return server, nil
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
