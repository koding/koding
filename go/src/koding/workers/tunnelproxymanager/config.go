package tunnelproxymanager

import (
	"errors"
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/koding/ec2dynamicdata"
	"github.com/koding/multiconfig"
)

// Config holds configuration parameters for tunnelproxymanager
type Config struct {
	// required
	AccessKeyID     string `required:"true"`
	SecretAccessKey string `required:"true"`

	// can be overriden
	Region          string
	EBEnvName       string
	AutoScalingName string
	HostedZone      HostedZone // defaults are in struct tags

	// optional
	Debug bool
}

type HostedZone struct {
	Name            string `default:"tunnelproxy.koding.com"`
	CallerReference string `default:"tunnelproxy_hosted_zone_v0"`
}

// Configure prepares configuration data for tunnelproxy manager
func Configure() (*Config, *aws.Config, error) {
	c := &Config{}
	multiconfig.New().MustLoad(c)

	// decide on region name
	region, err := getRegion(c)
	if err != nil {
		return nil, nil, err
	}

	c.Region = region

	// decide on eb env name
	ebEnvName, err := getEBEnvName(c)
	if err != nil {
		return nil, nil, err
	}

	c.EBEnvName = ebEnvName

	awsconfig := &aws.Config{
		Credentials: credentials.NewStaticCredentials(
			c.AccessKeyID,
			c.SecretAccessKey,
			"",
		),
		Region:     aws.String(c.Region),
		MaxRetries: aws.Int(5),
	}

	// decide on autoscaling name
	name, err := getAutoScalingName(c, awsconfig)
	if err != nil {
		return nil, nil, err
	}

	c.AutoScalingName = name
	return c, awsconfig, nil
}

// getRegion checks if region name is given in config, if not tries to get it
// from ec2dynamicdata endpoint
func getRegion(conf *Config) (string, error) {
	if conf.Region != "" {
		return conf.Region, nil
	}

	info, err := ec2dynamicdata.Get()
	if err != nil {
		return "", fmt.Errorf("couldn't get region. Err: %s", err.Error())
	}

	if info.Region == "" {
		return "", fmt.Errorf("malformed ec2dynamicdata response: %#v", info)
	}
	return info.Region, nil
}

// getEBEnvName checks if region name is given in config, if not tries to get it
// from env variable
func getEBEnvName(conf *Config) (string, error) {
	if conf.EBEnvName != "" {
		return conf.EBEnvName, nil
	}

	// get EB_ENV_NAME param
	ebEnvName := os.Getenv("EB_ENV_NAME")
	if ebEnvName == "" {
		return "", fmt.Errorf("EB_ENV_NAME can not be empty")
	}
	return ebEnvName, nil
}

// getAutoScalingName tries to get autoscaling name from system, first gets from
// config var, if not set then tries ec2dynamicdata service
func getAutoScalingName(conf *Config, awsconfig *aws.Config) (string, error) {
	if conf.AutoScalingName != "" {
		return conf.AutoScalingName, nil
	}

	info, err := ec2dynamicdata.Get()
	if err != nil {
		return "", fmt.Errorf("couldn't get info. Err: %s", err.Error())
	}

	instanceID := info.InstanceID

	asg := autoscaling.New(awsconfig)

	resp, err := asg.DescribeAutoScalingInstances(
		&autoscaling.DescribeAutoScalingInstancesInput{
			InstanceIds: []*string{
				aws.String(instanceID),
			},
		},
	)
	if err != nil {
		return "", err
	}

	for _, instance := range resp.AutoScalingInstances {
		if *instance.InstanceId == instanceID {
			return *instance.AutoScalingGroupName, nil
		}
	}
	return "", errors.New("couldn't find autoscaling name")
}
