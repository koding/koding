package koding

import (
	"errors"
	"fmt"
	"koding/db/mongodb"
	"koding/kites/klient/usage"
	"strconv"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/koding/kite"
	aws "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/amazon"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/ec2"
	"github.com/mitchellh/mapstructure"

	"koding/kites/kloud/provisioner"
)

var (
	// DefaultAMI = "ami-80778be8" // Ubuntu 14.0.4 EBS backed, amd64,  PV
	DefaultAMI          = "ami-864d84ee" // Ubuntu 14.04 EBS backed, amd64, HVM
	DefaultInstanceType = "t2.micro"
	DefaultRegion       = "us-east-1"

	kodingCredential = map[string]interface{}{
		"access_key": "AKIAI6IUMWKF3F4426CA",
		"secret_key": "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",
	}
)

const (
	ProviderName = "koding"
)

// Provider implements the kloud packages Storage, Builder and Controller
// interface
type Provider struct {
	Session      *mongodb.MongoDB
	AssigneeName string
	Log          logging.Logger
	Push         func(string, int, machinestate.State)

	// A flag saying if user permissions should be ignored
	// store negation so default value is aligned with most common use case
	Test bool

	// Contains the users home directory to be added into a image
	TemplateDir string
}

func (p *Provider) NewClient(machine *protocol.Machine) (*amazon.AmazonClient, error) {
	username := machine.Builder["username"].(string)

	a := &amazon.AmazonClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("%s - %s ==> %s", machine.MachineId, username, msg)

			machine.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
	}

	var err error

	machine.Builder["region"] = DefaultRegion
	a.Amazon, err = aws.New(kodingCredential, machine.Builder)
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

func (p *Provider) Build(opts *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	username := opts.Builder["username"].(string)

	instanceName := opts.Builder["instanceName"].(string)

	// this can happen when an Info method is called on a terminated instance.
	// This updates the DB records with the name that EC2 gives us, which is a
	// "terminated-instance"
	if instanceName == "terminated-instance" {
		instanceName = username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
		a.Log.Info("Instance name is an artifact (terminated), changing to %s", instanceName)
	}

	groupName := "koding-kloud" // TODO: make it from the package level and remove it from here
	a.Log.Info("Checking if security group '%s' exists", groupName)
	group, err := a.SecurityGroup(groupName)
	if err != nil {
		a.Log.Info("No security group with name: '%s' exists. Creating a new one...", groupName)
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

	// IMAGE BUILDER
	amiName, err := provisioner.Ami()
	if err != nil {
		return nil, fmt.Errorf("Could not get generated AMI name: %s", err)
	}

	// Build type needed for backer
	a.ImageBuilder.Type = "amazon-ebs"

	// SSH username
	a.ImageBuilder.SshUsername = "ubuntu"

	// Name of AMI to build if needed
	a.ImageBuilder.AmiName = amiName

	// Use this ami as a "foundation"
	a.ImageBuilder.SourceAmi = DefaultAMI

	// Region we're building in
	a.ImageBuilder.Region = a.Builder.Region

	// Build AMI for this instance type
	// Doesn't need VPC, etc ... and AMI can be used for t2.micro
	// plus the build is faster
	a.ImageBuilder.InstanceType = "m3.medium"

	// Credentials
	a.ImageBuilder.AccessKey = a.Creds.AccessKey
	a.ImageBuilder.SecretKey = a.Creds.SecretKey

	a.Log.Info("Checking if AMI named '%s' exists", amiName)
	image, err := a.ImageByName(amiName)
	if err != nil {
		a.Log.Error(err.Error())
		// Image doesn't exist so try it
		a.Log.Info("AMI named '%s' does not exist, building it now", amiName)
		a.Log.Info("Using templates from directory: %s", p.TemplateDir)

		image, err = a.CreateImage(provisioner.PackerRawData(p.TemplateDir))
		if err != nil {
			return nil, err
		}
	}

	// INSTANCE BUILDER

	// Get or build if needed AMI image
	a.Builder.SourceAmi = image.Id

	// add now our security group
	a.Builder.SecurityGroupId = group.Id

	// Use koding plans instead of those later
	a.Builder.InstanceType = DefaultInstanceType

	// needed for vpc instances, go and grap one from one of our Koding's own
	// subnets
	a.Log.Info("Searching for subnets")
	subs, err := a.ListSubnets()
	if err != nil {
		return nil, err
	}
	a.Builder.SubnetId = subs.Subnets[0].SubnetId

	cloudConfig := `
#cloud-config
disable_root: false
hostname: %s`

	// use a simple hostname, previously we were using instanceName which was
	// is long and more detailed
	hostname := username

	cloudStr := fmt.Sprintf(cloudConfig, hostname)

	a.Builder.UserData = []byte(cloudStr)

	artifact, err := a.Build(instanceName)
	if err != nil {
		return nil, err
	}

	// Add user specific tag to make it easier  simplfying easier
	a.Log.Info("Adding user tag '%s' to the instance '%s'", username, artifact.InstanceId)
	if err := a.AddTag(artifact.InstanceId, "koding-user", username); err != nil {
		return nil, err
	}

	return artifact, nil
}

// Remove the instance if something goes wrong
func (p *Provider) Cancel(opts *protocol.Machine, artifact *protocol.Artifact) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	if artifact == nil {
		return errors.New("artifact is passed nil")
	}

	_, err = a.Client.TerminateInstances([]string{artifact.InstanceId})
	if err != nil {
		return err
	}

	return nil
}

func (p *Provider) Start(opts *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return a.Start()
}

func (p *Provider) Stop(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Stop()
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

	return a.Destroy()
}

func (p *Provider) Info(opts *protocol.Machine) (*protocol.InfoArtifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return a.Info()
}

func (p *Provider) Report(r *kite.Request) (interface{}, error) {
	var usg usage.Usage
	err := r.Args.One().Unmarshal(&usg)
	if err != nil {
		return nil, err
	}

	m := &Machine{}
	err = p.Session.Run("jMachines", func(c *mgo.Collection) error {
		return c.Find(bson.M{"queryString": r.Client.Kite.String()}).One(&m)
	})
	if err != nil {
		p.Log.Warning("Couldn't find %v, however this kite is still reporting to us. Needs to be fixed: %s",
			r.Client.Kite, err.Error())
		return nil, errors.New("can't update report - 1")
	}

	machine, err := p.Get(m.Id.Hex(), r.Username)
	if err != nil {
		return nil, err
	}
	// release the lock from mongodb after we are done
	defer p.ResetAssignee(machine.MachineId)

	fmt.Printf("usage: %+v\n", usg)
	if usg.InactiveDuration >= time.Minute*30 {
		p.Log.Info("Stopping machine %s", machine.MachineId)

		err := p.Stop(machine)
		if err != nil {
			return nil, err
		}

		return "machine is stopped", nil
	}

	p.Log.Info("Machine '%s' is good to go", r.Client.Kite.ID)
	return true, nil
}
