package amazon

import (
	"errors"
	"fmt"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
	"github.com/mitchellh/mapstructure"
)

type Amazon struct {
	ec2 *ec2.EC2

	// Contains AccessKey and SecretKey
	Creds struct {
		AccessKey string
		SecretKey string
		Region    string
	}

	Builder struct{}
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

	a.ec2 = ec2.New(
		aws.Auth{
			AccessKey: a.Creds.AccessKey,
			SecretKey: a.Creds.SecretKey,
		},
		awsRegion,
	)

	return a, nil
}
