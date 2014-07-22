package koding

import (
	"errors"
	"fmt"
	"koding/db/mongodb"
	"time"

	aws "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/amazon"
	"github.com/mitchellh/goamz/ec2"

	"github.com/koding/logging"
)

var (
	// DefaultAMI = "ami-80778be8" // Ubuntu 14.0.4 EBS backed, amd64,  PV
	DefaultAMI          = "ami-a6926dce" // Ubuntu 14.04 EBS backed, amd64, HVM
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

type Provider struct {
	Log  logging.Logger
	Push func(string, int, machinestate.State)
	DB   *mongodb.MongoDB
}

func (p *Provider) NewClient(opts *protocol.MachineOptions) (*amazon.AmazonClient, error) {
	a := &amazon.AmazonClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("%s - %s ==> %s", opts.MachineId, opts.Username, msg)

			opts.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
		Deploy: opts.Deploy,
	}

	var err error

	opts.Builder["region"] = DefaultRegion
	a.Amazon, err = aws.New(kodingCredential, opts.Builder)
	if err != nil {
		return nil, err
	}

	return a, nil
}

func (p *Provider) Name() string {
	return ProviderName
}

func (p *Provider) Build(opts *protocol.MachineOptions) (*protocol.Artifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	if opts.InstanceName == "" {
		return nil, errors.New("server name is empty")
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

	// add now our security group
	a.Builder.SecurityGroupId = group.Id

	// Use koding plans instead of those later
	a.Builder.SourceAmi = DefaultAMI
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

	cloudStr := fmt.Sprintf(cloudConfig, opts.InstanceName)

	a.Builder.UserData = []byte(cloudStr)

	artifact, err := a.Build(opts.InstanceName)
	if err != nil {
		return nil, err
	}

	// Add user specific tag to make simplfying easier
	a.Log.Info("Adding user tag '%s' to the instance '%s'", opts.Username, artifact.InstanceId)
	if err := a.AddTag(artifact.InstanceId, "koding-user", opts.Username); err != nil {
		return nil, err
	}

	return artifact, nil
}

func (p *Provider) Start(opts *protocol.MachineOptions) (*protocol.Artifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return a.Start()
}

func (p *Provider) Stop(opts *protocol.MachineOptions) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Stop()
}

func (p *Provider) Restart(opts *protocol.MachineOptions) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Restart()
}

func (p *Provider) Destroy(opts *protocol.MachineOptions) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Destroy()
}

func (p *Provider) Info(opts *protocol.MachineOptions) (*protocol.InfoArtifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return a.Info()
}
