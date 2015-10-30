package awspurge

import (
	"errors"
	"net/http"
	"time"

	awsclient "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
)

type Config struct {
	Regions        []string      `toml:"regions" json:"regions"`
	RegionsExclude []string      `toml:"regions_exclude" json:"regions_exclude"`
	AccessKey      string        `toml:"access_key" json:"access_key"`
	SecretKey      string        `toml:"secret_key" json:"secret_key"`
	Timeout        time.Duration `toml:"timeout" json:"timeout"`
}

type Purge struct {
	services *multiRegion
}

func (p *Purge) Do() error {
	return errors.New("not implemented yet")
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
		services: m,
	}, nil
}
