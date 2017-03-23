package vagrant

import (
	"errors"
	"fmt"
	"os"

	konfig "koding/kites/config"
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
	config, err = konfig.ReadKiteConfig(debug)
	if err != nil {
		return err
	}

	config.Environment = Environment
	config.Region = Region

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

	k := kite.NewWithConfig(Name, Version, config)

	if debug {
		k.SetLogLevel(kite.DEBUG)
	}

	c := &Client{
		Kite: k,
		Log:  logging.NewCustom(Name, debug),
	}

	c.Log.Debug("starting provider-vagrant in debug mode")

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

	c.Username, ok = d.Get("username").(string)
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

	c.Debug, _ = d.Get("debug").(bool)

	if d.HasChange("forwarded_ports") {
		rawPorts := d.Get("forwarded_ports").([]interface{})

		for i, v := range rawPorts {
			m, ok := v.(map[string]interface{})
			if !ok {
				return nil, fmt.Errorf("invalid request: forwarded_ports #%d is not an object", i)
			}

			var port vagrantapi.ForwardedPort

			for k, v := range m {
				switch k {
				case "guest":
					n, ok := v.(int)
					if !ok {
						return nil, fmt.Errorf("invalid request: forwarded_ports #%d guest is not a number", i)
					}

					port.GuestPort = n
				case "host":
					n, ok := v.(int)
					if !ok {
						return nil, fmt.Errorf("invalid request: forwarded_ports #%d host is not a number", i)
					}

					port.HostPort = n
				}
			}

			if port.HostPort == 0 {
				port.HostPort = port.GuestPort
			}

			c.ForwardedPorts = append(c.ForwardedPorts, &port)
		}
	}

	return &c, nil
}
