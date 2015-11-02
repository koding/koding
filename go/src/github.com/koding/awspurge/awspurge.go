package awspurge

import (
	"errors"
	"fmt"
	"net/http"
	"sync"
	"time"

	awsclient "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/hashicorp/go-multierror"
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

	for _, region := range allRegions {
		p.resources[region] = &resources{
			instances: allInstances[region],
			volumes:   allVolumes[region],
		}
	}

	return nil
}

func (p *Purge) describeResources(fn func(*ec2.EC2) (interface{}, error)) (map[string]interface{}, error) {
	var (
		wg sync.WaitGroup
		mu sync.Mutex

		multiErrors error
	)

	output := make(map[string]interface{})

	for r, s := range p.services.regions {
		wg.Add(1)

		go func(region string, svc *ec2.EC2) {
			out, err := fn(svc)
			if err != nil {
				mu.Lock()
				multiErrors = multierror.Append(multiErrors, err)
				mu.Unlock()
				wg.Done()
				return
			}

			mu.Lock()
			output[region] = out
			mu.Unlock()

			wg.Done()
		}(r, s)
	}

	wg.Wait()

	return output, multiErrors
}

// DescribeVolumes returns all volumes per region.
func (p *Purge) DescribeVolumes() (map[string][]*ec2.Volume, error) {
	describeVolumes := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeVolumes(nil)
		if err != nil {
			return nil, err
		}

		return resp.Volumes, nil
	}

	out, err := p.describeResources(describeVolumes)
	if err != nil {
		return nil, err
	}

	volumes := make(map[string][]*ec2.Volume)
	for region, v := range out {
		vols, ok := v.([]*ec2.Volume)
		if !ok {
			continue
		}
		volumes[region] = vols
	}

	return volumes, nil
}

// DescribeInstances returns all instances per region.
func (p *Purge) DescribeInstances() (map[string][]*ec2.Instance, error) {
	describeInstances := func(svc *ec2.EC2) (interface{}, error) {
		resp, err := svc.DescribeInstances(nil)
		if err != nil {
			return nil, err
		}

		instances := make([]*ec2.Instance, 0)
		if resp.Reservations != nil {
			for _, reserv := range resp.Reservations {
				if len(reserv.Instances) != 0 {
					instances = append(instances, reserv.Instances...)
				}
			}
		}

		return instances, nil
	}

	out, err := p.describeResources(describeInstances)
	if err != nil {
		return nil, err
	}

	instances := make(map[string][]*ec2.Instance)
	for region, i := range out {
		ins, ok := i.([]*ec2.Instance)
		if !ok {
			continue
		}
		instances[region] = ins
	}

	return instances, nil
}
