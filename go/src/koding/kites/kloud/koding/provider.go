package koding

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"koding/db/mongodb"
	"koding/kites/kloud/klient"

	"github.com/koding/kite"
	"github.com/koding/kloud"
	amazonClient "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/amazon"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/ec2"
	"github.com/mitchellh/mapstructure"
)

var (
	DefaultCustomAMITag = "koding-stable" // Only use AMI's that have this tag
	DefaultInstanceType = "t2.micro"
	DefaultRegion       = "us-east-1"

	// Credential belongs to the `koding-kloud` user in AWS IAM's
	kodingCredential = map[string]interface{}{
		"access_key": "AKIAIDPT7E2UHZHT2CXQ",
		"secret_key": "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",
	}
)

const (
	ProviderName = "koding"
)

// Provider implements the kloud packages Storage, Builder and Controller
// interface
type Provider struct {
	Kite         *kite.Kite
	Session      *mongodb.MongoDB
	AssigneeName string
	Log          logging.Logger
	Push         func(string, int, machinestate.State)

	// A flag saying if user permissions should be ignored
	// store negation so default value is aligned with most common use case
	Test bool

	// Contains the users home directory to be added into a image
	TemplateDir string

	// DNS is used to create/update domain recors
	DNS        *DNS
	HostedZone string
}

func (p *Provider) NewClient(machine *protocol.Machine) (*amazon.AmazonClient, error) {
	username := machine.Builder["username"].(string)

	a := &amazon.AmazonClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("[%s] %s (username: %s)", machine.MachineId, msg, username)

			machine.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
	}

	var err error

	machine.Builder["region"] = DefaultRegion

	a.Amazon, err = amazonClient.New(kodingCredential, machine.Builder)
	if err != nil {
		return nil, fmt.Errorf("koding-amazon err: %s", err)
	}

	// also apply deploy variable if there is any
	if err := mapstructure.Decode(machine.Builder, &a.Deploy); err != nil {
		return nil, fmt.Errorf("koding-amazon: couldn't decode deploy variables: %s", err)
	}

	return a, nil
}

func (p *Provider) Name() string {
	return ProviderName
}

func (p *Provider) Build(opts *protocol.Machine) (protocolArtifact *protocol.Artifact, err error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	username := opts.Builder["username"].(string)

	instanceName := opts.Builder["instanceName"].(string)

	machineData, ok := opts.CurrentData.(*Machine)
	if !ok {
		return nil, fmt.Errorf("current data is malformed: %v", opts.CurrentData)
	}

	a.Push("Initializing data", 10, machinestate.Building)

	// make a custom logger which just prepends our machineid
	infoLog := func(format string, formatArgs ...interface{}) {
		format = "[%s] " + format
		args := []interface{}{opts.MachineId}
		args = append(args, formatArgs...)
		p.Log.Info(format, args...)
	}

	a.InfoLog = infoLog

	// this can happen when an Info method is called on a terminated instance.
	// This updates the DB records with the name that EC2 gives us, which is a
	// "terminated-instance"
	if instanceName == "terminated-instance" {
		instanceName = username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
		infoLog("Instance name is an artifact (terminated), changing to %s", instanceName)
	}

	a.Push("Checking security requirements", 20, machinestate.Building)

	groupName := "koding-kloud" // TODO: make it from the package level and remove it from here
	infoLog("Checking if security group '%s' exists", groupName)
	group, err := a.SecurityGroup(groupName)
	if err != nil {
		infoLog("No security group with name: '%s' exists. Creating a new one...", groupName)
		vpcs, err := a.ListVPCs()
		if err != nil {
			return nil, err
		}

		group = ec2.SecurityGroup{
			Name:        groupName,
			Description: "Koding Kloud Security Group",
			VpcId:       vpcs.VPCs[0].VpcId,
		}

		infoLog("Creating security group for this instance...")
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
		infoLog("Authorizing SSH access on the security group: '%s'", group.Id)
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

	// add now our security group
	a.Builder.SecurityGroupId = group.Id

	// Use koding plans instead of those later
	a.Builder.InstanceType = DefaultInstanceType

	// needed for vpc instances, go and grap one from one of our Koding's own
	// subnets
	infoLog("Searching for subnets")
	subs, err := a.ListSubnets()
	if err != nil {
		return nil, err
	}
	a.Builder.SubnetId = subs.Subnets[0].SubnetId

	a.Push("Checking base build image", 30, machinestate.Building)

	infoLog("Checking if AMI with tag '%s' exists", DefaultCustomAMITag)
	image, err := a.ImageByTag(DefaultCustomAMITag)
	if err != nil {
		return nil, err
	}

	// Use this ami id, which is going to be a stable one
	a.Builder.SourceAmi = image.Id

	cloudConfig := `
#cloud-config
disable_root: false
disable-ec2-metadata: true
hostname: %s`

	// use a simple hostname, previously we were using instanceName which was
	// is long and more detailed
	hostname := username

	cloudStr := fmt.Sprintf(cloudConfig, hostname)

	a.Builder.UserData = []byte(cloudStr)

	buildArtifact, err := a.Build(instanceName)
	if err != nil {
		return nil, err
	}

	buildArtifact.MachineId = opts.MachineId

	// cleanup build if something goes wrong here
	defer func() {
		if err != nil {
			p.Log.Warning("[%s] Cleaning up instance. Terminating instance: %s",
				opts.MachineId, buildArtifact.InstanceId)

			if _, err := a.Client.TerminateInstances([]string{buildArtifact.InstanceId}); err != nil {
				p.Log.Warning("[%s] Cleaning up instance failed: %v", opts.MachineId, err)
			}
		}
	}()

	// Add user specific tag to make it easier  simplfying easier
	infoLog("Adding username tag '%s' to the instance '%s'", username, buildArtifact.InstanceId)
	if err := a.AddTag(buildArtifact.InstanceId, "koding-user", username); err != nil {
		return nil, err
	}

	infoLog("Adding environment tag '%s' to the instance '%s'", p.Kite.Config.Environment, buildArtifact.InstanceId)
	if err := a.AddTag(buildArtifact.InstanceId, "koding-env", p.Kite.Config.Environment); err != nil {
		return nil, err
	}

	infoLog("Adding machineId tag '%s' to the instance '%s'", opts.MachineId, buildArtifact.InstanceId)
	if err := a.AddTag(buildArtifact.InstanceId, "koding-machineId", opts.MachineId); err != nil {
		return nil, err
	}

	a.Push("Checking domain", 65, machinestate.Building)

	/////// ROUTE 53 /////////////////
	if err := p.InitDNS(opts); err != nil {
		return nil, err
	}

	if err := validateDomain(machineData.Domain, username, p.HostedZone); err != nil {
		return nil, err
	}

	// Check if the record exist, if not return an error
	record, err := p.DNS.Domain(machineData.Domain)
	if err != nil && err != ErrNoRecord {
		return nil, err
	} else {
		if strings.Contains(record.Name, machineData.Domain) {
			return nil, fmt.Errorf("domain %s already exists", machineData.Domain)
		}
	}

	a.Push("Creating domain", 70, machinestate.Building)

	if err := p.DNS.CreateDomain(machineData.Domain, buildArtifact.IpAddress); err != nil {
		return nil, err
	}

	defer func() {
		if err != nil {
			p.Log.Warning("[%s] Cleaning up domain record. Deleting domain record: %s",
				opts.MachineId, machineData.Domain)
			if err := p.DNS.DeleteDomain(machineData.Domain, buildArtifact.IpAddress); err != nil {
				p.Log.Warning("[%s] Cleaning up domain failed: %v", opts.MachineId, err)
			}

		}
	}()

	infoLog("Adding user domain tag '%s' to the instance '%s'",
		machineData.Domain, buildArtifact.InstanceId)
	if err := a.AddTag(buildArtifact.InstanceId, "koding-domain", machineData.Domain); err != nil {
		return nil, err
	}

	a.Push("Starting provisioning", 75, machinestate.Building)

	buildArtifact.DomainName = machineData.Domain

	///// ROUTE 53 /////////////////
	return buildArtifact, nil
}

// CleanZoneID is used to remove the leading /hostedzone/
func CleanZoneID(ID string) string {
	if strings.HasPrefix(ID, "/hostedzone/") {
		ID = strings.TrimPrefix(ID, "/hostedzone/")
	}
	return ID
}

// Remove the instance if something goes wrong
// TODO: remove this after we moved deploy.go into cloud-init
func (p *Provider) Cancel(opts *protocol.Machine, artifact *protocol.Artifact) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	p.Log.Warning("Cancelling previous action for machine id: %s. Terminating instance: %s",
		opts.MachineId, artifact.InstanceId)
	_, err = a.Client.TerminateInstances([]string{artifact.InstanceId})
	if err != nil {
		p.Log.Warning("Cleaning up instance failed: %v", err)
	}

	if err := p.InitDNS(opts); err != nil {
		return err
	}

	username := opts.Builder["username"].(string)
	machineData := opts.CurrentData.(*Machine)

	if err := validateDomain(machineData.Domain, username, p.HostedZone); err != nil {
		return err
	}

	if err := p.DNS.DeleteDomain(machineData.Domain, artifact.IpAddress); err != nil {
		p.Log.Warning("Cleaning up domain failed: %v", err)
	}

	return nil
}

func (p *Provider) Start(opts *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	artifact, err := a.Start()
	if err != nil {
		return nil, err
	}

	machineData, ok := opts.CurrentData.(*Machine)
	if !ok {
		return nil, fmt.Errorf("current data is malformed: %v", opts.CurrentData)
	}

	a.Push("Initializing domain instance", 65, machinestate.Starting)

	/////// ROUTE 53 /////////////////
	if err := p.InitDNS(opts); err != nil {
		return nil, err
	}

	username := opts.Builder["username"].(string)

	if err := validateDomain(machineData.Domain, username, p.HostedZone); err != nil {
		return nil, err
	}

	a.Push("Checking domain", 70, machinestate.Starting)
	// Check if the record exist, if yes update the ip instead of creating a new one.
	record, err := p.DNS.Domain(machineData.Domain)
	if err == ErrNoRecord {
		a.Push("Creating domain", 75, machinestate.Starting)
		if err := p.DNS.CreateDomain(machineData.Domain, artifact.IpAddress); err != nil {
			return nil, err
		}
	} else if err != nil {
		// If it's something else just return it
		return nil, err
	}

	// Means the record exist, update it
	if err == nil {
		a.Push("Updating domain", 75, machinestate.Starting)
		p.Log.Warning("[%s] Domain '%s' already exists (that shouldn't happen). Going to update to new IP",
			machineData.Domain, opts.MachineId)
		if err := p.DNS.Update(machineData.Domain, record.Records[0], artifact.IpAddress); err != nil {
			return nil, err
		}
	}

	a.Log.Info("[%s] Updating user domain tag '%s' of instance '%s'",
		opts.MachineId, machineData.Domain, artifact.InstanceId)

	a.Push("Adding domain tag", 80, machinestate.Starting)
	if err := a.AddTag(artifact.InstanceId, "koding-domain", machineData.Domain); err != nil {
		return nil, err
	}

	artifact.DomainName = machineData.Domain

	///// ROUTE 53 /////////////////

	a.Push("Checking remote machine", 90, machinestate.Starting)
	p.Log.Info("[%s] Connecting to remote Klient instance", opts.MachineId)
	klientRef, err := klient.NewWithTimeout(p.Kite, machineData.QueryString, time.Minute*1)
	if err != nil {
		p.Log.Warning("Connecting to remote Klient instance err: %s", err)
	} else {
		defer klientRef.Close()
		p.Log.Info("[%s] Sending a ping message", opts.MachineId)
		if err := klientRef.Ping(); err != nil {
			p.Log.Warning("Sending a ping message err:", err)
		}
	}

	return artifact, nil
}

func (p *Provider) Stop(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	err = a.Stop()
	if err != nil {
		return err
	}

	/////// ROUTE 53 /////////////////
	username := opts.Builder["username"].(string)

	machineData, ok := opts.CurrentData.(*Machine)
	if !ok {
		return fmt.Errorf("current data is malformed: %v", opts.CurrentData)
	}

	a.Push("Initializing domain instance", 65, machinestate.Stopping)
	if err := p.InitDNS(opts); err != nil {
		return err
	}

	if err := validateDomain(machineData.Domain, username, p.HostedZone); err != nil {
		return err
	}

	a.Push("Deleting domain", 75, machinestate.Stopping)
	if err := p.DNS.DeleteDomain(machineData.Domain, machineData.IpAddress); err != nil {
		return err
	}

	///// ROUTE 53 /////////////////

	a.Push("Updating ip address", 85, machinestate.Stopping)
	if err := p.Update(opts.MachineId, &kloud.StorageData{
		Type: "stop",
		Data: map[string]interface{}{
			"ipAddress": "",
		},
	}); err != nil {
		p.Log.Error("[stop] storage update of essential data was not possible: %s", err.Error())
	}

	return nil
}

func (p *Provider) Restart(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Restart()
}

func (p *Provider) Destroy(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	err = a.Destroy()
	if err != nil {
		return err
	}

	/////// ROUTE 53 /////////////////

	username := opts.Builder["username"].(string)

	machineData, ok := opts.CurrentData.(*Machine)
	if !ok {
		return fmt.Errorf("current data is malformed: %v", opts.CurrentData)
	}

	if err := p.InitDNS(opts); err != nil {
		return err
	}

	if err := validateDomain(machineData.Domain, username, p.HostedZone); err != nil {
		return err
	}

	a.Push("Checking domain", 75, machinestate.Terminating)
	// Check if the record exist, it can be deleted via stop, therefore just
	// return lazily
	_, err = p.DNS.Domain(machineData.Domain)
	if err == ErrNoRecord {
		return nil
	}

	// If it's something else just return it
	if err != nil {
		return err
	}

	a.Push("Deleting domain", 85, machinestate.Terminating)
	if err := p.DNS.DeleteDomain(machineData.Domain, machineData.IpAddress); err != nil {
		return err
	}

	///// ROUTE 53 /////////////////
	return nil
}

func (p *Provider) Info(opts *protocol.Machine) (result *protocol.InfoArtifact, err error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	// otherwise ask AWS to get an machine state
	infoResp, err := a.Info()
	if err != nil {
		return nil, err
	}

	resultState := infoResp.State

	p.Log.Info("[%s] info initials: current db state is '%s'. amazon ec2 state is '%s'",
		opts.MachineId, opts.State, infoResp.State)

	// We have many states that defines a machine. We need to decide which one
	// is correct so we compare the result from the DB and Amazon. We check the
	// current state with the result from amamazon. If they are the in the
	// corresponding states we just return. However there are individual states
	// that needs special treatment.

	// corresponding states defines a map that defines a relationship from a DB
	// state to Amazon state.  That means say in DB we have the state
	// "machinestate.Building", this means the machine is in either Starting
	// mode or Terminated mode (if it was terminated before and not running
	// yet). Another example say we have the state "machinestate.Starting".
	// That means the state can be in Amazon: Starting, Running or even Stopped
	// (between the time Start is called and and info method is made.
	matchStates := map[machinestate.State][]machinestate.State{
		machinestate.Building: []machinestate.State{
			machinestate.Starting, machinestate.Terminated,
		},
		machinestate.Starting: []machinestate.State{
			machinestate.Starting, machinestate.Running, machinestate.Stopped,
		},
		machinestate.Stopping: []machinestate.State{
			machinestate.Stopping, machinestate.Stopped,
		},
		machinestate.Terminating: []machinestate.State{
			machinestate.Terminating, machinestate.Terminated,
		},
		machinestate.Updating:   []machinestate.State{machinestate.Running},
		machinestate.Stopped:    []machinestate.State{machinestate.Stopped},
		machinestate.Terminated: []machinestate.State{machinestate.Terminated},
	}

	// check now whether the amazone ec2 state does match one and is in
	// comparable bounds with the current state
	if infoResp.State.In(matchStates[opts.State]...) {
		p.Log.Info("[%s] info result  : db state matches amazon state. returning current state '%s'",
			opts.MachineId, opts.State)

		return &protocol.InfoArtifact{
			State: opts.State,
			Name:  infoResp.Name,
		}, nil
	}

	// we don't check if the state is something else. Klient is only
	// available when the machine is running
	if opts.State == machinestate.Running && infoResp.State == machinestate.Running {
		resultState = opts.State

		// for the rest ask again to klient so we know if it's running or not
		machineData, ok := opts.CurrentData.(*Machine)
		if !ok {
			return nil, fmt.Errorf("current data is malformed: %v", opts.CurrentData)
		}

		p.Log.Info("[%s] machine state is '%s'. pinging klient again to be sure.",
			opts.MachineId, infoResp.State)

		klientRef, err := klient.NewWithTimeout(p.Kite, machineData.QueryString, time.Second*5)
		if err != nil {
			p.Log.Warning("[%s] state is '%s' but I can't connect to klient.",
				opts.MachineId, resultState)
			resultState = machinestate.Stopped
		} else {
			defer klientRef.Close()

			if err := klientRef.Ping(); err != nil {
				p.Log.Warning("[%s] state is '%s' but I can't send a ping. Err: %s",
					opts.MachineId, resultState, err.Error())
				resultState = machinestate.Stopped
			}
		}

		p.Log.Info("[%s] info result  : fetched result from klient. returning '%s'",
			opts.MachineId, resultState)

		p.UpdateState(opts.MachineId, resultState)

		return &protocol.InfoArtifact{
			State: resultState,
			Name:  infoResp.Name,
		}, nil

	}

	p.Log.Info("[%s] info result  : state is incosistent. correcting it to amazon state '%s'",
		opts.MachineId, infoResp.State)

	// fix the incosistency
	p.UpdateState(opts.MachineId, infoResp.State)

	// there is an incosistency between the DB state and Amazon EC2 state. So
	// we are saying that the EC2 state is the correct one.
	return &protocol.InfoArtifact{
		State: infoResp.State,
		Name:  infoResp.Name,
	}, nil

}
