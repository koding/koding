package openstack

import (
	"fmt"

	os "github.com/koding/kloud/api/openstack"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/waitstate"
	"github.com/koding/logging"
	"github.com/rackspace/gophercloud"
)

type OpenstackClient struct {
	*os.Openstack
	Log    logging.Logger
	Push   func(string, int, machinestate.State)
	Deploy *protocol.ProviderDeploy
}

func (o *OpenstackClient) Build(instanceName, imageId, flavorId string) (*protocol.ProviderArtifact, error) {
	o.Push(fmt.Sprintf("Checking for image availability %s", imageId), 10, machinestate.Building)
	_, err := o.Image(imageId)
	if err != nil {
		return nil, err
	}

	// keyName will be empty if Deploy is not initialized
	keyName, err := o.CheckAndCreateKey()
	if err != nil {
		return nil, err
	}

	// check if the flavor does exist
	flavors, err := o.Flavors()
	if err != nil {
		return nil, err
	}

	if !flavors.Has(flavorId) {
		return nil, fmt.Errorf("Flavor id '%s' doesn't exist", DefaultFlavorId)
	}

	newServer := gophercloud.NewServer{
		Name:        instanceName,
		ImageRef:    imageId,
		FlavorRef:   flavorId,
		KeyPairName: keyName,
	}

	o.Push(fmt.Sprintf("Creating server %s", instanceName), 20, machinestate.Building)
	resp, err := o.Client.CreateServer(newServer)
	if err != nil {
		return nil, fmt.Errorf("Error creating server: %s", err)
	}

	// store successfull result here
	var server *gophercloud.Server
	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		server, err = o.Client.ServerById(resp.Id)
		if err != nil {
			return 0, err
		}

		o.Push(fmt.Sprintf("Starting server '%s', curent task state: '%s'",
			instanceName, server.OsExtStsTaskState), currentPercentage, machinestate.Building)
		return statusToState(server.Status), nil
	}

	ws := waitstate.WaitState{StateFunc: stateFunc, DesiredState: machinestate.Running, Start: 25, Finish: 60}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	o.Push(fmt.Sprintf("Server is created %s", instanceName), 70, machinestate.Building)

	var privateKey string
	if o.Deploy != nil {
		privateKey = o.Deploy.PrivateKey
	}

	return &protocol.ProviderArtifact{
		IpAddress:     server.AccessIPv4,
		InstanceName:  server.Name,
		InstanceId:    server.Id,
		SSHPrivateKey: privateKey,
	}, nil
}

func (o *OpenstackClient) CheckAndCreateKey() (string, error) {
	if o.Deploy == nil {
		return "", nil
	}

	// check if our key exist
	key, err := o.ShowKey(o.Deploy.KeyName)
	if err != nil {
		return "", err
	}

	if key.Name != "" {
		return key.Name, nil
	}

	// key doesn't exist, create a new one
	key, err = o.CreateKey(o.Deploy.KeyName, o.Deploy.PublicKey)
	if err != nil {
		return "", err
	}

	return key.Name, nil
}

func (o *OpenstackClient) Start() (*protocol.ProviderArtifact, error) {
	o.Push("Starting machine", 10, machinestate.Stopping)

	// keyName will be empty if Deploy is not initialized
	keyName, err := o.CheckAndCreateKey()
	if err != nil {
		return nil, err
	}

	o.Push(fmt.Sprintf("Checking if backup image '%s' exists", o.Builder.InstanceName),
		20, machinestate.Starting)
	images, err := o.Images()
	if err != nil {
		return nil, err
	}

	image, err := images.ImageByName(o.Builder.InstanceName)
	if err != nil {
		return nil, err
	}
	o.Push(fmt.Sprintf("Backup image '%s' does exists", o.Builder.InstanceName), 20, machinestate.Starting)

	newServer := gophercloud.NewServer{
		Name:        o.Builder.InstanceName,
		ImageRef:    image.Id,
		FlavorRef:   o.Builder.Flavor,
		KeyPairName: keyName,
	}

	o.Push(fmt.Sprintf("Starting server '%s' based on image id '%s' image name: %s",
		o.Builder.InstanceName, image.Id, image.Name), 30, machinestate.Starting)
	resp, err := o.Client.CreateServer(newServer)
	if err != nil {
		return nil, fmt.Errorf("Error creating server: %s", err)
	}

	// store successfull result here
	var server *gophercloud.Server
	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		server, err = o.Client.ServerById(resp.Id)
		if err != nil {
			return 0, err
		}

		o.Push(fmt.Sprintf("Starting server '%s', curent state: '%s'",
			o.Builder.InstanceName, server.OsExtStsTaskState), currentPercentage, machinestate.Starting)
		return statusToState(server.Status), nil
	}

	ws := waitstate.WaitState{StateFunc: stateFunc, DesiredState: machinestate.Running, Start: 35, Finish: 60}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	// now delete our backup image, we don't need it anymore
	o.Push(fmt.Sprintf("Deleting backup image %s - %s",
		image.Name, image.Id), 80, machinestate.Starting)
	if err := o.Client.DeleteImageById(image.Id); err != nil {
		return nil, err
	}

	return &protocol.ProviderArtifact{
		InstanceId:   server.Id,
		InstanceName: server.Name,
		IpAddress:    server.AccessIPv4,
	}, nil
}

func (o *OpenstackClient) Stop() error {
	o.Push("Stopping machine", 10, machinestate.Stopping)

	// create backup name the same as the given instanceName
	backup := gophercloud.CreateImage{
		Name: o.Builder.InstanceName,
	}

	o.Push(fmt.Sprintf("Creating a backup image with name: %s for id: %s",
		backup.Name, o.Id()), 20, machinestate.Stopping)
	respId, err := o.Client.CreateImage(o.Id(), backup)
	if err != nil {
		return err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		server, err := o.Server()
		if err != nil {
			return 0, err
		}

		// and empty taks means the image creating and uploading task has been
		// finished, now we can move on to the next step.
		if server.OsExtStsTaskState == "" {
			return machinestate.Stopping, nil
		}

		o.Push(fmt.Sprintf("Taking image '%s' of machine, curent state: '%s'",
			respId, server.OsExtStsTaskState), currentPercentage, machinestate.Stopping)
		return statusToState(server.Status), nil
	}

	ws := waitstate.WaitState{StateFunc: stateFunc, DesiredState: machinestate.Stopping, Start: 30, Finish: 50}
	if err := ws.Wait(); err != nil {
		return err
	}

	o.Push(fmt.Sprintf("Deleting server: %s", o.Id()), 55, machinestate.Stopping)
	if err := o.Client.DeleteServerById(o.Id()); err != nil {
		return err
	}

	stateFunc = func(currentPercentage int) (machinestate.State, error) {
		server, err := o.Server()
		if err == os.ErrServerNotFound {
			return machinestate.Stopped, nil
		}

		o.Push(fmt.Sprintf("Deleting server '%s', curent task state: '%s'",
			server.Name, server.OsExtStsTaskState), currentPercentage, machinestate.Stopping)

		return statusToState(server.Status), nil
	}

	ws = waitstate.WaitState{StateFunc: stateFunc, DesiredState: machinestate.Stopped, Start: 60, Finish: 80}
	return ws.Wait()
}

func (o *OpenstackClient) Restart() error {
	o.Push("Rebooting machine", 10, machinestate.Rebooting)
	hardShutdown := false
	if err := o.Client.RebootServer(o.Id(), hardShutdown); err != nil {
		return err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		server, err := o.Server()
		if err != nil {
			return machinestate.Unknown, err
		}

		o.Push(fmt.Sprintf("Rebooting server '%s', curent task state: '%s'", server.Name, server.OsExtStsTaskState), 50, machinestate.Rebooting)
		return statusToState(server.Status), nil
	}

	ws := waitstate.WaitState{StateFunc: stateFunc, DesiredState: machinestate.Running, Start: 30, Finish: 70}
	return ws.Wait()
}

func (o *OpenstackClient) Destroy() error {
	o.Push("Terminating machine", 10, machinestate.Terminating)
	if err := o.Client.DeleteServerById(o.Id()); err != nil {
		return nil
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		server, err := o.Server()
		if err == os.ErrServerNotFound {
			// server is not destroyed
			return machinestate.Terminated, nil
		}

		if err != nil {
			return machinestate.Unknown, err
		}

		o.Push(fmt.Sprintf("Deleting server '%s', curent task state: '%s'",
			o.Builder.InstanceName, server.OsExtStsTaskState), 50, machinestate.Terminating)

		return statusToState(server.Status), nil
	}

	ws := waitstate.WaitState{StateFunc: stateFunc, DesiredState: machinestate.Terminated, Start: 30, Finish: 70}
	return ws.Wait()
}

func (o *OpenstackClient) Info() (*protocol.InfoArtifact, error) {
	o.Log.Debug("Checking for server info: %s", o.Id())
	var err error
	server := &gophercloud.Server{}
	server, err = o.Server()
	if err == os.ErrServerNotFound {
		o.Log.Debug("Server does not exist, checking if it has a backup image")
		images, err := o.Images()
		if err != nil {
			return nil, err
		}

		if images.HasName(o.Builder.InstanceName) {
			// means the machine was deleted and an image exist that points to it
			o.Log.Debug("Image '%s' does exist, means it's stopped.", o.Builder.InstanceName)
			return &protocol.InfoArtifact{
				State: machinestate.Stopped,
				Name:  o.Builder.InstanceName,
			}, nil

		}

		o.Log.Debug("Image does not exist, returning unknown state.")
		return &protocol.InfoArtifact{
			State: machinestate.Terminated,
			Name:  o.Builder.InstanceName,
		}, nil
	}

	if statusToState(server.Status) == machinestate.Unknown {
		o.Log.Warning("Unknown rackspace status: %s. This needs to be fixed.", server.Status)
	}

	return &protocol.InfoArtifact{
		State: statusToState(server.Status),
		Name:  server.Name,
	}, nil
}
