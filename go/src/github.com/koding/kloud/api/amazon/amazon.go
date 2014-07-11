package amazon

import (
	"errors"
	"fmt"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
	"github.com/mitchellh/mapstructure"
)

type Amazon struct {
	Client *ec2.EC2

	// Contains AccessKey and SecretKey
	Creds struct {
		AccessKey string
		SecretKey string

		// The name of the region, such as "us-east-1", in which to launch the
		// EC2 instance
		Region string
	}

	Builder struct {
		// The EC2 instance type to use while building the AMI, such as
		// "m1.small" (required)
		InstanceType string `mapstructure:"instance_type"`

		// The initial AMI used as a base for the newly created machine. (required)
		SourceAmi string `mapstructure:"source_ami"`

		// KeyPair defines the name which is used creating an EC2 instance. (optional)
		// IMPORTANT: If you launch an instance without specifying a key pair,
		// you can't connect to the instance.
		KeyPair string `mapstructure:"key_pair"`

		// SecurityGroup defines one security group ID (optional)
		SecurityGroupId string `mapstructure:"security_group_id"`
	}
}

func New(credential, builder map[string]interface{}) (*Amazon, error) {
	a := &Amazon{}

	// Credentials
	if err := mapstructure.Decode(credential, &a.Creds); err != nil {
		return nil, err
	}

	// Builder data
	if err := mapstructure.Decode(builder, &a.Builder); err != nil {
		return nil, err
	}

	if a.Creds.AccessKey == "" {
		return nil, errors.New("credentials accessKey is empty")
	}

	if a.Creds.SecretKey == "" {
		return nil, errors.New("credentials secretKey is empty")
	}

	if a.Creds.Region == "" {
		return nil, errors.New("region is required")
	}

	awsRegion, ok := aws.Regions[a.Creds.Region]
	if !ok {
		return nil, fmt.Errorf("region is not an AWS region: %s", a.Creds.Region)
	}

	a.Client = ec2.New(
		aws.Auth{
			AccessKey: a.Creds.AccessKey,
			SecretKey: a.Creds.SecretKey,
		},
		awsRegion,
	)

	return a, nil
}
