package tunnelproxymanager

import (
	"fmt"
	"koding/ec2info"
	"os"

	"github.com/koding/multiconfig"
)

// Config holds configuration parameters for tunnelproxymanager
type Config struct {
	EBEnvName string
	Region    string // optional

	AutoScalingName string `required:"true"`
	AccessKeyID     string `required:"true" default:""`
	SecretAccessKey string `required:"true" default:""`
	Debug           bool
}

// Configure prepares configuration data for tunnelproxy manager
func Configure() (*Config, error) {
	c := &Config{}
	multiconfig.New().MustLoad(c)

	// decide on region name
	region, err := getRegion(c)
	if err != nil {
		return nil, err
	}

	c.Region = region

	// decide on eb env name
	ebEnvName, err := getEBEnvName(c)
	if err != nil {
		return nil, err
	}

	c.EBEnvName = ebEnvName

	return c, nil
}

// getRegion checks if region name is given in config, if not tries to get it
// from ec2metadata endpoint
func getRegion(conf *Config) (string, error) {
	if conf.Region != "" {
		return conf.Region, nil
	}

	info, err := ec2info.Get()
	if err != nil {
		return "", fmt.Errorf("couldn't get region. Err: %s", err.Error())
	}

	if info.Region == "" {
		return "", fmt.Errorf("got malformed data from ec2metadata service")
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
		return "", fmt.Errorf("EB Env Name can not be empty")
	}

	return ebEnvName, nil
}
