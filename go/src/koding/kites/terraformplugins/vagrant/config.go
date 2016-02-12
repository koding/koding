package vagrant

import (
	"os"

	"koding/kites/common"

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

type Client struct {
	// Kite is used for remote communication
	Kite *kite.Kite

	// Logger is used internally
	Log logging.Logger
}

// NewClient returns client with required properties for accessing remote
// klient.
func NewClient() (*Client, error) {
	// init kite here
	k := kite.New(Name, Version)

	var err error
	k.Config, err = kiteconfig.Get()
	if err != nil {
		return nil, err
	}

	// no need to set, will be set randomly.
	// k.Config.Port = 9876
	k.Config.Environment = Environment
	k.Config.Region = Region
	k.Config.Transport = kiteconfig.XHRPolling

	return &Client{
		Kite: k,
		Log:  common.NewLogger(Name, os.Getenv("CONFIG_DEBUG") == "1"),
	}, nil

}

// Close closes the underlying properties
func (c *Client) Close() error {
	c.Kite.Close()
	return nil
}
