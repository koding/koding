package digitalocean

import (
	"errors"
	do "koding/kites/kloud/api/digitalocean"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"

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

	Region      string
	Environment string
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
		CachePrefix: "cache-" + p.Region + "-" + p.Environment,
		Redis:       p.Redis,
		RedisPrefix: p.Redis.AddPrefix(""),
	}
	c.DigitalOcean = d

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
func (p *Provider) Build(opts *protocol.MachineOptions) (*protocol.BuildResponse, error) {
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

func (p *Provider) Start(opts *protocol.MachineOptions) error {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return doClient.Start()
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

func (p *Provider) Info(opts *protocol.MachineOptions) (*protocol.InfoResponse, error) {
	doClient, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	return doClient.Info()
}
