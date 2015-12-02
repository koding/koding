package amazon

import (
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/mitchellh/mapstructure"
)

type Amazon struct {
	*Client

	// Contains AccessKey and SecretKey
	Creds struct {
		AccessKey string `mapstructure:"access_key"`
		SecretKey string `mapstructure:"secret_key"`
	}

	Builder struct {
		// Populated by Kloud
		InstanceId   string `mapstructure:"instanceId"`
		InstanceName string `mapstructure:"instanceName"`

		// The EC2 instance type to use while building the AMI, such as
		// "m1.small" (required)
		InstanceType string `mapstructure:"instance_type"`

		// StorageSize is used to create an instance with a larger storage
		StorageSize        int                     `mapstructure:"storage_size"`
		BlockDeviceMapping *ec2.BlockDeviceMapping `mapstructure:"block_device_mapping"`

		// The initial AMI used as a base for the newly created machine. (required)
		SourceAmi string `mapstructure:"source_ami"`

		// The name of the region, such as "us-east-1", in which to launch the
		// EC2 instance
		Region string `mapstructure:"region"`

		// The name of the zone, such as "us-east-1b", in which to launch the
		// EC2 instance
		Zone string `mapstructure:"zone"`

		// KeyPair defines the name which is used creating an EC2 instance. (optional)
		// IMPORTANT: If you launch an instance without specifying a key pair,
		// you can't connect to the instance.
		KeyPair string `mapstructure:"key_pair"`

		// PublicKey and PrivateKey is used to create a new KeyPair.
		PublicKey  string `mapstructure:"publicKey"`
		PrivateKey string `mapstructure:"privateKey"`

		// SecurityGroup defines one security group ID (optional)
		SecurityGroupId string `mapstructure:"security_group_id"`

		// If using VPC, the ID of the subnet, such as "subnet-12345def" Some
		// of the instance types, such as t2.micro can be only launched in a
		// VPC
		SubnetId string `mapstructure:"subnet_id"`

		// If usign VPC subnet, the ID of the VPC, such as "vpc-12345def"
		VpcId string `mapstructure:"vpc_id"`

		// UserData can be passed to pre initialized instances via cloud-init
		UserData []byte `mapstructure:"user_data"`
	}
}

func New(builder map[string]interface{}, client *Client) (*Amazon, error) {
	a := &Amazon{
		Client: client,
	}

	// Builder data
	if err := mapstructure.Decode(builder, &a.Builder); err != nil {
		return nil, err
	}

	return a, nil
}

func NewWithOptions(builder map[string]interface{}, opts *ClientOptions) (*Amazon, error) {
	client, err := NewClient(opts)
	if err != nil {
		return nil, err
	}
	return New(builder, client)
}

// Id returns the instances unique Id
func (a *Amazon) Id() string {
	return a.Builder.InstanceId
}
