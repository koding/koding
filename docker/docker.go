// Package docker provides a layer on top of Docker's API via Kite handlers.
package docker

import (
	"errors"
	"fmt"
	"io"
	"os"
	"strconv"
	"sync"
	"time"
	"unicode/utf8"

	"github.com/docker/docker/pkg/promise"
	"github.com/koding/klient/Godeps/_workspace/src/code.google.com/p/go-charset/charset"
	_ "github.com/koding/klient/Godeps/_workspace/src/code.google.com/p/go-charset/data"
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
func New(url string, log kite.Logger) *Docker {
	// the error is returned only when the passed URL is not parsable via
	// url.Parse, so we can safely neglect it
	client, _ := dockerclient.NewVersionedClient(url, "1.16")
	return &Docker{
		client: client,
		log:    log,
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

// Connect connects to an existing Container by spawning a new process and
// attaching to it.
func (d *Docker) Connect(r *kite.Request) (interface{}, error) {
	var params struct {
		// The ID of the container.
		ID string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if params.ID == "" {
		return nil, errors.New("missing arg: container ID is empty")
	}

	createOpts := dockerclient.CreateExecOptions{
		// Container: params.ID,
		Container: "high_torvalds",
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
	fmt.Printf("ex = %+v\n", ex)

	opts := dockerclient.StartExecOptions{
		Detach:       false,
		Tty:          true,
		OutputStream: os.Stdout,
		ErrorStream:  os.Stdout,
		InputStream:  os.Stdin,
	}

	errCh := promise.Go(func() error {
		d.log.Info("starting exec instance '%s'", ex.ID)
		return d.client.StartExec(ex.ID, opts)
	})

	d.log.Info("Resizing exec instance '%s'", ex.ID)
	if err := d.client.ResizeExecTTY(ex.ID, 28, 208); err != nil {
		fmt.Printf("resize exec err %+v\n", err)
	}

	fmt.Println("waiting err from errch")
	if err := <-errCh; err != nil {
		fmt.Printf("hijack err = %+v\n", err)
		return nil, err
	}

	return true, nil
}

// Exec connects to an existing Container by spawning a new process and
// attaching to it.
func (d *Docker) Exec(r *kite.Request) (interface{}, error) {
	var params struct {
		// The ID of the container.
		ID string

		Remote       Remote
		Session      string
		SizeX, SizeY int
		Mode         string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	// if params.ID == "" {
	// 	return nil, errors.New("missing arg: container ID is empty")
	// }

	d.log.Info("params %+v\n", params)

	//////////////////
	imageOpts := dockerclient.CreateContainerOptions{
		Name: "webtest",
		Config: &dockerclient.Config{
			Image:        "redis",
			Tty:          true,
			AttachStdin:  true,
			AttachStdout: true,
			AttachStderr: true,
		},
	}

	container, err := d.client.CreateContainer(imageOpts)
	if err == nil {
		// if successfull start it
		if err := d.client.StartContainer(container.ID, nil); err != nil {
			// return nil, err
			d.log.Error("starting error: %s", err)
		}
	} else {
		d.log.Error("creating error: %s", err)
	}

	//////////////////

	createOpts := dockerclient.CreateExecOptions{
		Container: container.ID,
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

	outReadPipe, outWritePipe := io.Pipe()
	inReadPipe, inWritePipe := io.Pipe()

	opts := dockerclient.StartExecOptions{
		Detach:       false,
		Tty:          true,
		OutputStream: outWritePipe,
		ErrorStream:  outWritePipe,
		InputStream:  inReadPipe,
	}

	masterEncoded, err := charset.NewWriter("ISO-8859-1", inWritePipe)
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
		controlSequence: masterEncoded,
		closeChan:       closeCh,
		client:          d.client,
	}

	go func() {
		d.log.Info("Starting exec instance '%s'", ex.ID)
		err := d.client.StartExec(ex.ID, opts)
		errCh <- err
	}()

	go func() {
		select {
		case err := <-errCh:
			if err != nil {
				d.log.Error("startExec error: err")
			}
		case <-closeCh:
			// TODO close hijacker's connection. We need to modify startExec
		}

	}()

	var once sync.Once

	// Read the STDOUT from shell process and send to the connected client.
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

			out := string(filterInvalidUTF8(buf[:n]))
			fmt.Printf("out = %+v\n", out)
			server.remote.Output.Call(string(filterInvalidUTF8(buf[:n])))
			if err != nil {
				break
			}
		}
		d.log.Info("Breaking out of for loop")
	}()

	d.log.Info("Returning server")
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
