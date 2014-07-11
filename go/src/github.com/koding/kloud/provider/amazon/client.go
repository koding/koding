package amazon

import (
	"fmt"
	"strconv"
	"time"

	aws "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/ec2"
)

type AmazonClient struct {
	*aws.Amazon
	Log    logging.Logger
	Push   func(string, int, machinestate.State)
	Deploy *protocol.ProviderDeploy
}

func (a *AmazonClient) Build(instanceName string) (*protocol.ProviderArtifact, error) {
	a.Log.Info("Checking if image '%s' exists", a.Builder.SourceAmi)
	_, err := a.Image(a.Builder.SourceAmi)
	if err != nil {
		return nil, err
	}

	groupName := "koding-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	a.Log.Info("Temporary group name: %s", groupName)

	group := ec2.SecurityGroup{
		Name:        groupName,
		Description: "Temporary group for Koding Kloud",
	}

	a.Log.Info("Creating temporary security group for this instance...")
	groupResp, err := a.Client.CreateSecurityGroup(group)
	if err != nil {
		return nil, err
	}

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
	a.Log.Info("Authorizing SSH access on the temporary security group...")
	for i := 0; i < 5; i++ {
		_, err = a.Client.AuthorizeSecurityGroup(groupResp.SecurityGroup, perms)
		if err == nil {
			break
		}

		a.Log.Warning("Error authorizing. Will sleep and retry. %s", err)
		time.Sleep((time.Duration(i) * time.Second) + 1)
	}
	if err != nil {
		return nil, fmt.Errorf("Error creating temporary security group: %s", err)
	}

	var keyName string
	if a.Deploy != nil {
		resp, err := a.Showkey(a.Deploy.KeyName)
		if err != nil {
			return nil, err
		}

		fmt.Printf("resp %+v\n", resp)

		// a.CreateKey(a.Deploy.KeyName, a.de
	}

	// add now our temporary security group
	// TODO: remove it after we are done
	a.Builder.SecurityGroupId = groupResp.Id

	// Create instance with this keypair
	a.Builder.KeyPair = keyName

	a.Log.Info("Creating instance")
	resp, err := a.CreateInstance()
	if err != nil {
		return nil, err
	}

	// we do not check intentionally, because CreateInstance() is designed to
	// create only one instance. If it creates something else we catch it here
	// by panicing
	instance := resp.Instances[0]

	// Rename the
	a.Log.Info("Adding the tag '%s' to the instance id '%s'", instanceName, instance.InstanceId)
	if err := a.AddTag(instance.InstanceId, "Name", instanceName); err != nil {
		return nil, err
	}

	var privateKey string
	if a.Deploy != nil {
		privateKey = a.Deploy.PrivateKey
	}

	return &protocol.ProviderArtifact{
		IpAddress:     instance.PublicIpAddress,
		InstanceName:  instanceName,
		InstanceId:    instance.InstanceId,
		SSHPrivateKey: privateKey,
	}, nil
}
