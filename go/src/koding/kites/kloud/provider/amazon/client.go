package amazon

import (
	"errors"
	"strings"

	aws "koding/kites/kloud/api/amazon"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/waitstate"

	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/mitchellh/goamz/ec2"
)

type AmazonClient struct {
	*aws.Amazon
	Log  logging.Logger
	Push func(string, int, machinestate.State)

	// Used for customization
	InfoLog func(string, ...interface{})
	Metrics *metrics.DogStatsD
}

func (a *AmazonClient) BuildWithCheck(buildData *ec2.RunInstances, start, finish int) (*protocol.Artifact, error) {
	debugLog := func(format string, args ...interface{}) {
		a.Log.Debug(format, args...)
	}

	// Don't build anything without this, otherwise ec2 complains about it as a
	// missing paramater.
	if a.Builder.SecurityGroupId == "" {
		return nil, errors.New("security group id is empty.")
	}

	// Make sure AMI exists
	debugLog("Checking if image '%s' exists", a.Builder.SourceAmi)
	if _, err := a.Image(a.Builder.SourceAmi); err != nil {
		if err != nil {
			return nil, err
		}
	}

	// Get the necessary keynames that we are going to provide with Amazon. If
	// it doesn't exist a new one will be created.  check if the key exist, if
	// yes return the keyname
	debugLog("Checking if keypair '%s' does exist", a.Builder.KeyPair)
	keyName, err := a.DeployKey()
	if err != nil {
		return nil, err
	}

	// Create instance with this keypair
	a.Builder.KeyPair = keyName

	debugLog("Creating instance with type: '%s' based on AMI: '%s'",
		a.Builder.InstanceType, a.Builder.SourceAmi)

	instanceId, err := a.Build(buildData)
	if err != nil {
		return nil, err
	}

	instance, err := a.CheckBuild(instanceId, start, finish)
	if err != nil {
		return nil, err
	}

	return &protocol.Artifact{
		IpAddress:    instance.PublicIpAddress,
		InstanceId:   instance.InstanceId,
		InstanceType: a.Builder.InstanceType,
	}, nil
}

func (a *AmazonClient) Build(buildData *ec2.RunInstances) (string, error) {
	resp, err := a.Client.RunInstances(buildData)
	if err != nil {
		return "", err
	}

	// we do not check intentionally, because CreateInstance() is designed to
	// create only one instance. If it creates something else we catch it here
	// by panicing
	instance := resp.Instances[0]

	a.Log.Debug("EC2 Build instance response: %#v", instance)

	return instance.InstanceId, nil
}

func (a *AmazonClient) CheckBuild(instanceId string, start, finish int) (ec2.Instance, error) {
	var instance ec2.Instance
	var err error
	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		a.track(instanceId, "Build")

		instance, err = a.Instance(instanceId)
		if err != nil {
			a.Log.Warning("getting build creating status failed, trying again. Err: '%s'", err)
			return 0, err
		}

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc: stateFunc,
		PushFunc:  a.Push,
		Action:    "build",
		Start:     start,
		Finish:    finish,
	}

	if err := ws.Wait(); err != nil {
		return ec2.Instance{}, err
	}

	return instance, nil
}

func (a *AmazonClient) DeployKey() (string, error) {
	resp, err := a.Showkey(a.Builder.KeyPair)
	if err == nil {
		// key is found
		return resp.Keys[0].Name, nil
	}

	// not a ec2 error, return it
	ec2Err, ok := err.(*ec2.Error)
	if !ok {
		return "", err
	}

	// the key has another problem
	if ec2Err.Code != "InvalidKeyPair.NotFound" {
		return "", err
	}

	// ok now the key is not found, means it needs to be created
	a.Log.Info("Keypair '%s' doesn't exist, creating a new one", a.Builder.KeyPair)

	if a.Builder.PublicKey == "" {
		return "", errors.New("PublicKey is not defined. Can't create key")
	}

	key, err := a.CreateKey(a.Builder.KeyPair, a.Builder.PublicKey)
	if err != nil {
		return "", err
	}

	return key.KeyName, nil
}

func (a *AmazonClient) track(id string, call string) {
	tags := []string{"action:" + call}

	if id != "" {
		tags = append(tags, "instanceId:"+id)
	}

	if a.Metrics == nil {
		return
	}

	a.Metrics.Count(
		"call_to_describe_instance.counter", // metric name
		1,    // count
		tags, // tags for metric call
		1.0,  // rate
	)
}

func (a *AmazonClient) Start(withPush bool) (*protocol.Artifact, error) {
	if withPush {
		a.Push("Starting machine", 10, machinestate.Starting)
	}

	_, err := a.Client.StartInstances(a.Id())
	if err != nil {
		return nil, err
	}

	var instance ec2.Instance
	stateFunc := func(currentPercentage int) (machinestate.State, error) {

		a.track(a.Id(), "Start")

		instance, err = a.Instance(a.Id())
		if err != nil {
			return 0, err
		}

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc: stateFunc,
		PushFunc:  a.Push,
		Action:    "start",
		Start:     25,
		Finish:    60,
	}

	if err := ws.Wait(); err != nil {
		return nil, err
	}

	return &protocol.Artifact{
		InstanceId:   instance.InstanceId,
		IpAddress:    instance.PublicIpAddress,
		InstanceType: a.Builder.InstanceType,
	}, nil
}

func (a *AmazonClient) Stop(withPush bool) error {
	if withPush {
		a.Push("Stopping machine", 10, machinestate.Stopping)
	}

	_, err := a.Client.StopInstances(a.Id())
	if err != nil {
		return err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		a.track(a.Id(), "Stop")

		instance, err := a.Instance(a.Id())
		if err != nil {
			return 0, err
		}

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc: stateFunc,
		PushFunc:  a.Push,
		Action:    "stop",
		Start:     25,
		Finish:    60,
	}

	return ws.Wait()
}

func (a *AmazonClient) Restart(withPush bool) error {
	if withPush {
		a.Push("Restarting machine", 10, machinestate.Rebooting)
	}

	_, err := a.Client.RebootInstances(a.Id())
	if err != nil {
		return err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		a.track(a.Id(), "Restart")

		instance, err := a.Instance(a.Id())
		if err != nil {
			return 0, err
		}

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc: stateFunc,
		PushFunc:  a.Push,
		Action:    "restart",
		Start:     25,
		Finish:    60,
	}

	return ws.Wait()
}

func (a *AmazonClient) Destroy(start, finish int) error {
	if a.Id() == "" {
		return errors.New("instance id is empty")
	}

	a.Push("Terminating machine", start, machinestate.Terminating)
	_, err := a.Client.TerminateInstances([]string{a.Id()})
	if err != nil {
		return err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		a.track(a.Id(), "Destroy")

		instance, err := a.Instance(a.Id())
		if err != nil {
			return 0, err
		}

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc: stateFunc,
		PushFunc:  a.Push,
		Action:    "destroy",
		Start:     start,
		Finish:    finish,
	}

	return ws.Wait()
}

func (a *AmazonClient) Info() (*protocol.InfoArtifact, error) {
	if a.Id() == "" {
		return &protocol.InfoArtifact{
			State: machinestate.NotInitialized,
			Name:  "not-existing-instance",
		}, nil
	}

	a.track(a.Id(), "Info")

	instance, err := a.Instance(a.Id())
	if err == aws.ErrNoInstances {
		return &protocol.InfoArtifact{
			State: machinestate.NotInitialized,
			Name:  "not-existing-instance",
		}, nil
	}

	// if it's something else, return it back
	if err != nil {
		return nil, err
	}

	if statusToState(instance.State.Name) == machinestate.Unknown {
		a.Log.Warning("Unknown amazon status: %+v. This needs to be fixed.", instance.State)
	}

	var instanceName string
	for _, tag := range instance.Tags {
		if tag.Key == "Name" {
			instanceName = tag.Value
		}
	}

	// this shouldn't happen
	if instanceName == "" {
		a.Log.Warning("instance %s doesn't have a name tag. needs to be fixed!", a.Id())
	}

	return &protocol.InfoArtifact{
		State:        statusToState(instance.State.Name),
		Name:         instanceName,
		InstanceType: instance.InstanceType,
	}, nil

}

// statusToState converts a amazon status to a sensible machinestate.State
// format
func statusToState(status string) machinestate.State {
	status = strings.ToLower(status)

	// Valid values: pending | running | shutting-down | terminated | stopping | stopped

	switch status {
	case "pending":
		return machinestate.Starting
	case "running":
		return machinestate.Running
	case "stopped":
		return machinestate.Stopped
	case "stopping":
		return machinestate.Stopping
	case "shutting-down":
		return machinestate.Terminating
	case "terminated":
		return machinestate.Terminated
	default:
		return machinestate.Unknown
	}
}
