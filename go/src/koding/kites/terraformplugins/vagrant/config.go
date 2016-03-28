package vagrant

import (
	"errors"
	"os"

	"koding/kites/common"
	"koding/kites/kloud/api/vagrantapi"
	"koding/tools/util"

	"github.com/hashicorp/terraform/helper/schema"
	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/logging"
)

var (
	Version     = "0.0.1"
	Name        = "vagrant"
	Environment = "terraform"
	Region      = "terraform"
)

var (
	once   util.OnceSuccessful
	config *kiteconfig.Config
	debug  = os.Getenv("CONFIG_DEBUG") == "1"
)

func newConfig() error {
	var err error
	config, err = kiteconfig.Get()
	if err != nil {
		return err
	}

	config.Environment = Environment
	config.Region = Region
	config.Transport = kiteconfig.XHRPolling

	return nil
}

type Client struct {
	// Kite is used for remote communication
	Kite *kite.Kite

	// Logger is used internally
	Log logging.Logger

	// Vagrant is a client for klient/vagrant kite methods.
	Vagrant *vagrantapi.Klient
}

// NewClient returns client with required properties for accessing remote
// klient.
func NewClient() (*Client, error) {
	// Parse kite.key only once.
	if err := once.Do(newConfig); err != nil {
		return nil, err
	}

	k := kite.New(Name, Version)
	k.Config = config.Copy()

	c := &Client{
		Kite: k,
		Log:  common.NewLogger(Name, debug),
	}

	c.Vagrant = &vagrantapi.Klient{
		Kite:  k,
		Log:   c.Log.New("vagrantapi"),
		Debug: debug,
	}

	return c, nil
}

// Close closes the underlying properties
func (c *Client) Close() error {
	c.Kite.Close()
	return nil
}

func newCreateReq(d *schema.ResourceData) (*vagrantapi.Create, error) {
	var ok bool
	var c vagrantapi.Create

	c.FilePath, ok = d.Get("filePath").(string)
	if !ok {
		return nil, errors.New("invalid request: filePath field is missing")
	}

	c.ProvisionData, ok = d.Get("provisionData").(string)
	if !ok {
		return nil, errors.New("invalid request: provisionData field is missing")
	}

	c.Box, ok = d.Get("box").(string)
	if !ok {
		return nil, errors.New("invalid request: box field is missing")
	}

	c.Hostname, ok = d.Get("hostname").(string)
	if !ok {
		return nil, errors.New("invalid request: hostname field is missing")
	}

	c.Memory, ok = d.Get("memory").(int)
	if !ok {
		return nil, errors.New("invalid request: memory field is missing")
	}

	c.Cpus, ok = d.Get("cpus").(int)
	if !ok {
		return nil, errors.New("invalid request: cpus field is missing")
	}

	c.CustomScript, ok = d.Get("user_data").(string)
	if !ok {
		return nil, errors.New("invalid request: user_data field is missing")
	}

	return &c, nil
}
