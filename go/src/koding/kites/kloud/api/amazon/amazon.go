package amazon

import (
	"errors"
	"fmt"
	"net"
	"net/http"
	"time"

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

	// include it here to because the library is not exporting it.
	var retryingTransport = &aws.ResilientTransport{
		Deadline: func() time.Time {
			return time.Now().Add(5 * time.Second)
		},
		DialTimeout: 30 * time.Second, // this is 10 seconds in original
		MaxTries:    3,
		ShouldRetry: awsRetry,
		Wait:        aws.ExpBackoff,
	}

	a.Client = ec2.NewWithClient(
		aws.Auth{
			AccessKey: a.Creds.AccessKey,
			SecretKey: a.Creds.SecretKey,
		},
		awsRegion,
		aws.NewClient(retryingTransport),
	)

	return a, nil
}

// Id returns the instances unique Id
func (a *Amazon) Id() string {
	return a.Builder.InstanceId
}

// Decide if we should retry a request.  In general, the criteria for retrying
// a request is described here
// http://docs.aws.amazon.com/general/latest/gr/api-retries.html
//
// arslan: this is a slightly modified version that also includes timeouts,
// original file: https://github.com/mitchellh/goamz/blob/master/aws/client.go
func awsRetry(req *http.Request, res *http.Response, err error) bool {
	retry := false

	// Retry if there's a temporary network error or a timeout.
	if neterr, ok := err.(net.Error); ok {
		if neterr.Temporary() {
			retry = true
		}

		if neterr.Timeout() {
			retry = true
		}
	}

	// Retry if we get a 5xx series error.
	if res != nil {
		if res.StatusCode >= 500 && res.StatusCode < 600 {
			retry = true
		}
	}

	return retry
}
