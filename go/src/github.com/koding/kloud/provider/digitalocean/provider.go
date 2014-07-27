package digitalocean

import (
	"errors"
	"fmt"

	do "github.com/koding/kloud/api/digitalocean"
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/mitchellh/mapstructure"

	"github.com/koding/logging"
	"github.com/koding/redis"
)

const (
	ProviderName = "digitalocean"
	PoolSize     = 10
)

type Provider struct {
	Log         logging.Logger
	Push        func(string, int, machinestate.State)
	PoolEnabled bool
	Redis       *redis.RedisSession
}

func (p *Provider) NewClient(opts *protocol.Machine) (*Client, error) {
	username := opts.Builder["username"].(string)

	d, err := do.New(opts.Credential, opts.Builder)
	if err != nil {
		return nil, fmt.Errorf("digitalocean err: %s", err)
	}

	if opts.Eventer == nil {
		return nil, errors.New("Eventer is not defined.")
	}

	push := func(msg string, percentage int, state machinestate.State) {
		p.Log.Info("%s - %s ==> %s", opts.MachineId, username, msg)

		opts.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     state,
			Percentage: percentage,
		})
	}

	c := &Client{
		Push:        push,
		Log:         p.Log,
		Caching:     true,
		CachePrefix: "cache-digitalocean",
	}
	c.DigitalOcean = d

	// also apply deploy variable if there is any
	if err := mapstructure.Decode(opts.Builder, &c.Deploy); err != nil {
		return nil, fmt.Errorf("digitalocean: couldn't decode deploy variables: %s", err)
	}

	if p.Redis != nil {
		c.Redis = p.Redis
		c.RedisPrefix = p.Redis.AddPrefix("")
	}

	p.Push = push
	return c, nil
}

func (p *Provider) Name() string {
	return ProviderName
}

// Build is building an image and creates a droplet based on that image. If the
// given snapshot/image exist it directly skips to creating the droplet. It
// acceps two string arguments, first one is the snapshotname, second one is
// the dropletName.
func (p *Provider) Build(opts *protocol.Machine) (*protocol.Artifact, error) {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	dropletName := opts.Builder["instanceName"].(string)

	return doClient.Build(dropletName)
}

func (p *Provider) Start(opts *protocol.Machine) (*protocol.Artifact, error) {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return nil, doClient.Start()
}

func (p *Provider) Stop(opts *protocol.Machine) error {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return doClient.Stop()
}

func (p *Provider) Restart(opts *protocol.Machine) error {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return doClient.Restart()
}

func (p *Provider) Destroy(opts *protocol.Machine) error {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return doClient.Destroy()
}

func (p *Provider) Info(opts *protocol.Machine) (*protocol.InfoArtifact, error) {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return doClient.Info()
}
