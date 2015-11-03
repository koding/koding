package awspurge

import (
	"errors"
	"fmt"
	"net/http"
	"time"

	awsclient "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/service/ec2"
)

type Config struct {
	Regions        []string      `toml:"regions" json:"regions"`
	RegionsExclude []string      `toml:"regions_exclude" json:"regions_exclude"`
	AccessKey      string        `toml:"access_key" json:"access_key"`
	SecretKey      string        `toml:"secret_key" json:"secret_key"`
	Timeout        time.Duration `toml:"timeout" json:"timeout"`
}

type resources struct {
	instances []*ec2.Instance
	volumes   []*ec2.Volume
	keyPairs  []*ec2.KeyPairInfo
}

type Purge struct {
	services *multiRegion

	// resources represents the current available resources per region. It's
	// populated by the Fetch() method.
	resources map[string]*resources
}

func New(conf *Config) (*Purge, error) {
	checkCfg := "Please check your configuration"

	if len(conf.Regions) == 0 {
		return nil, errors.New("AWS Regions are not set. " + checkCfg)
	}

	if conf.AccessKey == "" {
		return nil, errors.New("AWS Access Key is not set. " + checkCfg)
	}

	if conf.SecretKey == "" {
		return nil, errors.New("AWS Secret Key is not set. " + checkCfg)
	}

	if conf.Timeout == 0 {
		conf.Timeout = time.Second * 30
	}

	client := &http.Client{
		Transport: &http.Transport{TLSHandshakeTimeout: conf.Timeout},
		Timeout:   conf.Timeout,
	}

	creds := credentials.NewStaticCredentials(conf.AccessKey, conf.SecretKey, "")
	awsCfg := &awsclient.Config{
		Credentials: creds,
		HTTPClient:  client,
		Logger:      awsclient.NewDefaultLogger(),
	}

	m := newMultiRegion(awsCfg, filterRegions(conf.Regions, conf.RegionsExclude))
	return &Purge{
		services:  m,
		resources: make(map[string]*resources, 0),
	}, nil
}

func (p *Purge) Do() error {
	if err := p.Fetch(); err != nil {
		return err
	}

	if err := p.Print(); err != nil {
		return err
	}

	return nil
}

// Print prints all fetched resources
func (p *Purge) Print() error {
	for region, resources := range p.resources {
		fmt.Printf("[%s] found '%d' instances\n", region, len(resources.instances))
		fmt.Printf("[%s] found '%d' volumes\n", region, len(resources.volumes))
		fmt.Printf("[%s] found '%d' keyPairs\n", region, len(resources.keyPairs))
	}
	return nil
}

// Fetch fetches all given resources and stores them internally. To print them
// use the Print() method
func (p *Purge) Fetch() error {
	allInstances, err := p.DescribeInstances()
	if err != nil {
		return err
	}

	allVolumes, err := p.DescribeVolumes()
	if err != nil {
		return err
	}

	allKeyPairs, err := p.DescribeKeyPairs()
	if err != nil {
		return err
	}

	for _, region := range allRegions {
		p.resources[region] = &resources{
			instances: allInstances[region],
			volumes:   allVolumes[region],
			keyPairs:  allKeyPairs[region],
		}
	}

	return nil
}
