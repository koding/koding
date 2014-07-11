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
		AccessKey string `mapstructure:"access_key"`
		SecretKey string `mapstructure:"secret_key"`
	}

	Builder struct {
		// The EC2 instance type to use while building the AMI, such as
		// "m1.small" (required)
		InstanceType string `mapstructure:"instance_type"`

		// The initial AMI used as a base for the newly created machine. (required)
		SourceAmi string `mapstructure:"source_ami"`

		// The name of the region, such as "us-east-1", in which to launch the
		// EC2 instance
		Region string `mapstructure:"region"`

		// KeyPair defines the name which is used creating an EC2 instance. (optional)
		// IMPORTANT: If you launch an instance without specifying a key pair,
		// you can't connect to the instance.
		KeyPair string `mapstructure:"key_pair"`

		// SecurityGroup defines one security group ID (optional)
		SecurityGroupId string `mapstructure:"security_group_id"`

		// If using VPC, the ID of the subnet, such as "subnet-12345def" Some
		// of the instance types, such as t2.micro can be only launched in a
		// VPC
		SubnetId string `mapstructure:"subnet_id"`

		// If usign VPC subnet, the ID of the VPC, such as "vpc-12345def"
		VpcId string `mapstructure:"vpc_id"`
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

	if a.Builder.Region == "" {
		return nil, errors.New("region is required")
	}

	awsRegion, ok := aws.Regions[a.Builder.Region]
	if !ok {
		return nil, fmt.Errorf("region is not an AWS region: %s", a.Builder.Region)
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
