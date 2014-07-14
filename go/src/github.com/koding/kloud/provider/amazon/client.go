package amazon

import (
	"fmt"
	"strings"
	"time"

	aws "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/waitstate"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/ec2"
)

type AmazonClient struct {
	*aws.Amazon
	Log    logging.Logger
	Push   func(string, int, machinestate.State)
	Deploy *protocol.ProviderDeploy
}

func (a *AmazonClient) Build(instanceName string) (*protocol.Artifact, error) {
	// create it here because we might put some state data into Artifact Storage
	artifact := protocol.NewArtifact()

	a.Log.Info("Checking if image '%s' exists", a.Builder.SourceAmi)
	_, err := a.Image(a.Builder.SourceAmi)
	if err != nil {
		return nil, err
	}

	groupName := "koding-kloud" // TODO: make it from the package level and remove it from here
	a.Log.Info("Checking if security group '%s' exists", groupName)
	group, err := a.SecurityGroup(groupName)
	if err != nil {
		vpcs, err := a.ListVPCs()
		if err != nil {
			return nil, err
		}

		group = ec2.SecurityGroup{
			Name:        groupName,
			Description: "Koding Kloud Security Group",
			VpcId:       vpcs.VPCs[0].VpcId,
		}

		a.Log.Info("Creating security group for this instance...")
		// TODO: remove it after we are done
		groupResp, err := a.Client.CreateSecurityGroup(group)
		if err != nil {
			return nil, err
		}
		group = groupResp.SecurityGroup

		// Authorize the SSH access
		perms := []ec2.IPPerm{
			ec2.IPPerm{
				Protocol:  "tcp",
				FromPort:  22,
				ToPort:    22,
				SourceIPs: []string{"0.0.0.0/0"},
			},
		}

		// We loop and retry this a few times because sometimes the security
		// group isn't available immediately because AWS resources are eventaully
		// consistent.
		a.Log.Info("Authorizing SSH access on the security group: '%s'", group.Id)
		for i := 0; i < 5; i++ {
			_, err = a.Client.AuthorizeSecurityGroup(group, perms)
			if err == nil {
				break
			}

			a.Log.Warning("Error authorizing. Will sleep and retry. %s", err)
			time.Sleep((time.Duration(i) * time.Second) + 1)
		}
		if err != nil {
			return nil, fmt.Errorf("Error creating temporary security group: %s", err)
		}
	}

	// get the necessary keynames that we are going to provide with Amazon. If
	// it doesn't exist a new one will be created.
	keyName, err := a.DeployKey()
	if err != nil {
		return nil, err
	}

	// add now our security group
	a.Builder.SecurityGroupId = group.Id

	// Create instance with this keypair, if Deploy is not initialized it will
	// be a empty key pair, means no one is able to ssh into the machine.
	a.Builder.KeyPair = keyName

	subs, err := a.ListSubnets()
	if err != nil {
		return nil, err
	}

	a.Builder.SubnetId = subs.Subnets[0].SubnetId

	a.Log.Info("Creating instance with type: '%s' based on AMI: '%s'",
		a.Builder.InstanceType, a.Builder.SourceAmi)
	resp, err := a.CreateInstance()
	if err != nil {
		return nil, err
	}

	// we do not check intentionally, because CreateInstance() is designed to
	// create only one instance. If it creates something else we catch it here
	// by panicing
	instance := resp.Instances[0]

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		instance, err = a.Instance(instance.InstanceId)
		if err != nil {
			return 0, err
		}

		a.Push(fmt.Sprintf("Launching instance '%s'. Current state: %s",
			instanceName, instance.State.Name),
			currentPercentage, machinestate.Building)
		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Running,
		Start:        25,
		Finish:       60,
	}
	if err := ws.Wait(); err != nil {
		return nil, err
	}

	// Rename the machine
	a.Log.Info("Adding the tag '%s' to the instance '%s'", instanceName, instance.InstanceId)
	if err := a.AddTag(instance.InstanceId, "Name", instanceName); err != nil {
		return nil, err
	}

	var privateKey string
	var sshUsername string
	if a.Deploy != nil {
		privateKey = a.Deploy.PrivateKey
		sshUsername = a.Deploy.Username
	}

	artifact.IpAddress = instance.PublicIpAddress
	artifact.InstanceName = instanceName
	artifact.InstanceId = instance.InstanceId
	artifact.SSHPrivateKey = privateKey
	artifact.SSHUsername = sshUsername
	return artifact, nil
}

func (a *AmazonClient) DeployKey() (string, error) {
	if a.Deploy == nil {
		return "", nil
	}

	// check if the key exist, if yes return the keyname
	resp, err := a.Showkey(a.Deploy.KeyName)
	if err == nil {
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
	key, err := a.CreateKey(a.Deploy.KeyName, a.Deploy.PublicKey)
	if err != nil {
		return "", err
	}

	return key.KeyName, nil
}

func (a *AmazonClient) Start() (*protocol.Artifact, error) {
	a.Push("Starting machine", 10, machinestate.Starting)
	_, err := a.Client.StartInstances(a.Id())
	if err != nil {
		return nil, err
	}

	var instance ec2.Instance
	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		instance, err = a.Instance(a.Id())
		if err != nil {
			return 0, err
		}

		a.Push(fmt.Sprintf("Starting instance '%s'. Current state: %s",
			a.Builder.InstanceName, instance.State.Name),
			currentPercentage, machinestate.Starting)

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Running,
		Start:        25,
		Finish:       60,
	}

	if err := ws.Wait(); err != nil {
		return nil, err
	}

	artifact := protocol.NewArtifact()
	artifact.InstanceId = instance.InstanceId
	artifact.InstanceName = instance.Tags[0].Value
	artifact.IpAddress = instance.PublicIpAddress

	return artifact, nil
}

func (a *AmazonClient) Stop() error {
	a.Push("Stopping machine", 10, machinestate.Stopping)
	_, err := a.Client.StopInstances(a.Id())
	if err != nil {
		return err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		instance, err := a.Instance(a.Id())
		if err != nil {
			return 0, err
		}

		a.Push(fmt.Sprintf("Stopping instance '%s'. Current state: %s",
			a.Builder.InstanceName, instance.State.Name),
			currentPercentage, machinestate.Stopping)

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Stopped,
		Start:        25,
		Finish:       60,
	}

	return ws.Wait()
}

func (a *AmazonClient) Restart() error {
	a.Push("Restarting machine", 10, machinestate.Rebooting)
	_, err := a.Client.RebootInstances(a.Id())
	if err != nil {
		return err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		instance, err := a.Instance(a.Id())
		if err != nil {
			return 0, err
		}

		a.Push(fmt.Sprintf("Rebooting instance '%s'. Current state: %s",
			a.Builder.InstanceName, instance.State.Name),
			currentPercentage, machinestate.Rebooting)

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Running,
		Start:        25,
		Finish:       60,
	}

	return ws.Wait()
}

func (a *AmazonClient) Destroy() error {
	a.Push("Terminating machine", 10, machinestate.Terminating)
	_, err := a.Client.TerminateInstances([]string{a.Id()})
	if err != nil {
		return err
	}

	stateFunc := func(currentPercentage int) (machinestate.State, error) {
		instance, err := a.Instance(a.Id())
		if err != nil {
			return 0, err
		}

		a.Push(fmt.Sprintf("Terminating instance '%s'. Current state: %s",
			a.Builder.InstanceName, instance.State.Name),
			currentPercentage, machinestate.Terminating)

		return statusToState(instance.State.Name), nil
	}

	ws := waitstate.WaitState{
		StateFunc:    stateFunc,
		DesiredState: machinestate.Terminated,
		Start:        25,
		Finish:       60,
	}

	return ws.Wait()
}

func (a *AmazonClient) Info() (*protocol.InfoArtifact, error) {
	instance, err := a.Instance(a.Id())
	if err != nil {
		return nil, err
	}

	if statusToState(instance.State.Name) == machinestate.Unknown {
		a.Log.Warning("Unknown amazon status: %+v. This needs to be fixed.", instance.State)
	}

	return &protocol.InfoArtifact{
		State: statusToState(instance.State.Name),
		Name:  instance.Tags[0].Value,
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
