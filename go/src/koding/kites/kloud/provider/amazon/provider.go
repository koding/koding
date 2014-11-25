package amazon

import (
	"errors"
	"fmt"

	amazonClient "koding/kites/kloud/api/amazon"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"

	"github.com/koding/logging"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
)

type Provider struct {
	Log  logging.Logger
	Push func(string, int, machinestate.State)
}

func (p *Provider) NewClient(m *protocol.Machine) (*AmazonClient, error) {
	a := &AmazonClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("%s - %s ==> %s", m.Id, m.Username, msg)

			m.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
	}

	var awsRegion aws.Region
	if r, ok := m.Builder["region"]; ok {
		if region, ok := r.(string); ok {
			awsRegion, ok = aws.Regions[region]
			if !ok {
				return nil, fmt.Errorf("region is not an AWS region: '%s'", region)
			}
		}
	}

	var auth aws.Auth
	if c, ok := m.Credential["access_key"]; ok {
		if accessKey, ok := c.(string); ok {
			auth.AccessKey = accessKey
		}
	}

	if c, ok := m.Credential["secret_key"]; ok {
		if secretKey, ok := c.(string); ok {
			auth.SecretKey = secretKey
		}
	}

	client := ec2.New(auth, awsRegion)

	var err error
	a.Amazon, err = amazonClient.New(m.Builder, client)
	if err != nil {
		return nil, fmt.Errorf("amazon err: %s", err)
	}

	return a, nil
}

func (p *Provider) Name() string {
	return "amazon"
}

func (p *Provider) Build(m *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	if a.Builder.SourceAmi == "" {
		return nil, errors.New("source ami is empty")
	}

	if a.Builder.InstanceType == "" {
		return nil, errors.New("instance type is empty")
	}

	securityGroups := []ec2.SecurityGroup{{Id: a.Builder.SecurityGroupId}}

	runOpts := &ec2.RunInstances{
		ImageId:                  a.Builder.SourceAmi,
		MinCount:                 1,
		MaxCount:                 1,
		KeyName:                  a.Builder.KeyPair,
		InstanceType:             a.Builder.InstanceType,
		AssociatePublicIpAddress: true,
		SubnetId:                 a.Builder.SubnetId,
		UserData:                 a.Builder.UserData,
		SecurityGroups:           securityGroups,
		AvailZone:                a.Builder.Zone,
	}

	// only add blockdevice if it's being added to prevent errors on aws
	if a.Builder.BlockDeviceMapping != nil {
		runOpts.BlockDevices = []ec2.BlockDeviceMapping{*a.Builder.BlockDeviceMapping}
	}

	instanceId, err := a.Build(runOpts)
	if err != nil {
		return nil, err
	}

	instance, err := a.CheckBuild(instanceId, 10, 90)
	if err != nil {
		return nil, err
	}

	return &protocol.Artifact{
		IpAddress:    instance.PublicIpAddress,
		InstanceId:   instance.InstanceId,
		InstanceType: a.Builder.InstanceType,
	}, nil
}

func (p *Provider) Cancel(m *protocol.Machine) error {
	return nil
}

func (p *Provider) Start(m *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	return a.Start(true)
}

func (p *Provider) Stop(m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return a.Stop(true)
}

func (p *Provider) Restart(m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return a.Restart(true)
}

func (p *Provider) Destroy(m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return a.Destroy(10, 90)
}

func (p *Provider) Info(m *protocol.Machine) (*protocol.InfoArtifact, error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	return a.Info()
}

func (p *Provider) Resize(m *protocol.Machine) (*protocol.Artifact, error) {
	return nil, errors.New("resize is not supported")
}

func (p *Provider) Reinit(m *protocol.Machine) (*protocol.Artifact, error) {
	return nil, errors.New("reinitialize is not supported")
}
