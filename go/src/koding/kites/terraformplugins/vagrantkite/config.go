package vagrantkite

import (
	"koding/kites/common"

	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"

	"github.com/koding/logging"
)

const (
	version     = "0.0.1"
	name        = "vagrantkite"
	environment = "terraform"
	region      = "terraform"
)

type Client struct {
	Kite *kite.Kite
	Log  logging.Logger
}

// Client returns  client for accessing github.
func NewClient() (*Client, error) {
	// init kite here
	k := kite.New(name, version)

	var err error
	k.Config, err = kiteconfig.Get()
	if err != nil {
		return nil, err
	}

	// no need to set, will be set randomly.
	// k.Config.Port = 9876
	k.Config.Environment = environment
	k.Config.Region = region

	return &Client{
		Kite: k,
		Log:  common.NewLogger(name, false),
	}, nil

}

func (c *Client) Close() error {
	c.Kite.Close()
	return nil
}
