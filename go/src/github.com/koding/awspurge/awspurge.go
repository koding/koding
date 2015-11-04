package awspurge

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/aws/aws-sdk-go/service/elb"
)

type Config struct {
	Regions        []string      `toml:"regions" json:"regions"`
	RegionsExclude []string      `toml:"regions_exclude" json:"regions_exclude"`
	AccessKey      string        `toml:"access_key" json:"access_key"`
	SecretKey      string        `toml:"secret_key" json:"secret_key"`
	Timeout        time.Duration `toml:"timeout" json:"timeout"`
}

type resources struct {
	instances       []*ec2.Instance
	volumes         []*ec2.Volume
	keyPairs        []*ec2.KeyPairInfo
	placementGroups []*ec2.PlacementGroup
	addresses       []*ec2.Address
	snapshots       []*ec2.Snapshot
	loadBalancers   []*elb.LoadBalancerDescription
	securityGroups  []*ec2.SecurityGroup
}

type Purge struct {
	services *multiRegion

	// resources represents the current available resources per region. It's
	// populated by the Fetch() method.
	resources  map[string]*resources
	resourceMu sync.Mutex // protects resources

	// fetch synchronization
	wg   sync.WaitGroup
	mu   sync.Mutex
	errs error
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
	awsCfg := &aws.Config{
		Credentials: creds,
		HTTPClient:  client,
		Logger:      aws.NewDefaultLogger(),
	}

	m := newMultiRegion(awsCfg, filterRegions(conf.Regions, conf.RegionsExclude))

	// initialize resources
	res := make(map[string]*resources, 0)
	for _, region := range allRegions {
		res[region] = &resources{}
	}

	return &Purge{
		services:  m,
		resources: res,
	}, nil
}

func (p *Purge) Do() error {
	if err := p.Fetch(); err != nil {
		log.Println("Fetch err: %s", err)
	}

	if err := p.Print(); err != nil {
		return err
	}

	return nil
}

// Print prints all fetched resources
func (p *Purge) Print() error {
	for region, resources := range p.resources {
		fmt.Println("REGION:", region)
		fmt.Printf("\t'%d' instances\n", len(resources.instances))
		fmt.Printf("\t'%d' volumes\n", len(resources.volumes))
		fmt.Printf("\t'%d' keyPairs\n", len(resources.keyPairs))
		fmt.Printf("\t'%d' placementGroups\n", len(resources.placementGroups))
		fmt.Printf("\t'%d' addresses\n", len(resources.addresses))
		fmt.Printf("\t'%d' snapshots\n", len(resources.snapshots))
		fmt.Printf("\t'%d' loadbalancers\n", len(resources.loadBalancers))
		fmt.Printf("\t'%d' securitygroups\n", len(resources.securityGroups))
	}
	return nil
}

// Fetch fetches all given resources and stores them internally. To print them
// use the Print() method
func (p *Purge) Fetch() error {
	p.FetchInstances()
	p.FetchVolumes()
	p.FetchKeyPairs()
	p.FetchPlacementGroups()
	p.FetchAddresses()
	p.FetchSnapshots()
	p.FetchLoadBalancers()
	p.FetchSecurityGroups()

	p.wg.Wait()
	return p.errs
}
