package digitalocean

import (
	"errors"

	do "github.com/koding/kloud/api/digitalocean"
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"

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

func (p *Provider) NewClient(opts *protocol.MachineOptions) (*Client, error) {
	d, err := do.New(opts.Credential, opts.Builder)
	if err != nil {
		return nil, err
	}

	if opts.Eventer == nil {
		return nil, errors.New("Eventer is not defined.")
	}

	push := func(msg string, percentage int, state machinestate.State) {
		p.Log.Info("%s - %s ==> %s", opts.MachineId, opts.Username, msg)

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
func (p *Provider) Build(opts *protocol.MachineOptions) (*protocol.ProviderArtifact, error) {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	if opts.ImageName == "" {
		opts.ImageName = "ubuntu-14-04-x64"
	}

	if opts.InstanceName == "" {
		return nil, errors.New("dropletName is empty")
	}

	if opts.Username == "" {
		return nil, errors.New("username is empty")
	}

	return doClient.Build(opts.ImageName, opts.InstanceName, opts.Username)
}

func (p *Provider) Start(opts *protocol.MachineOptions) (*protocol.ProviderArtifact, error) {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return nil, doClient.Start()
}

func (p *Provider) Stop(opts *protocol.MachineOptions) error {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return doClient.Stop()
}

func (p *Provider) Restart(opts *protocol.MachineOptions) error {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return doClient.Restart()
}

func (p *Provider) Destroy(opts *protocol.MachineOptions) error {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return doClient.Destroy()
}

func (p *Provider) Info(opts *protocol.MachineOptions) (*protocol.InfoArtifact, error) {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return doClient.Info()
}
