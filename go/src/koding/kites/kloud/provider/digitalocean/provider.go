package digitalocean

import (
	"errors"
	"fmt"

	do "koding/kites/kloud/api/digitalocean"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"

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

	PublicKey  string
	PrivateKey string
	KeyName    string
}

func (p *Provider) NewClient(m *protocol.Machine) (*Client, error) {
	d, err := do.New(m.Credential, m.Builder)
	if err != nil {
		return nil, fmt.Errorf("digitalocean err: %s", err)
	}

	if m.Eventer == nil {
		return nil, errors.New("Eventer is not defined.")
	}

	push := func(msg string, percentage int, state machinestate.State) {
		p.Log.Info("%s - %s ==> %s", m.Id, m.Username, msg)

		m.Eventer.Push(&eventer.Event{
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

	// For now we assume that every client deploys this one particular key,
	// however we can easily override it from the `m` data (mongodb) and
	// replace it with user's own key.

	// needed to deploy during build
	c.Builder.KeyName = p.KeyName

	// needed to create the keypair if it doesn't exist
	c.Builder.PublicKey = p.PublicKey
	c.Builder.PrivateKey = p.PrivateKey

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
func (p *Provider) Build(m *protocol.Machine) (*protocol.Artifact, error) {
	doClient, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	dropletName := m.Builder["instanceName"].(string)

	return doClient.Build(dropletName)
}

func (p *Provider) Start(m *protocol.Machine) (*protocol.Artifact, error) {
	doClient, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	return nil, doClient.Start()
}

func (p *Provider) Stop(m *protocol.Machine) error {
	doClient, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return doClient.Stop()
}

func (p *Provider) Restart(m *protocol.Machine) error {
	doClient, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return doClient.Restart()
}

func (p *Provider) Destroy(m *protocol.Machine) error {
	doClient, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return doClient.Destroy()
}

func (p *Provider) Info(m *protocol.Machine) (*protocol.InfoArtifact, error) {
	doClient, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	return doClient.Info()
}

func (p *Provider) Resize(m *protocol.Machine) (*protocol.Artifact, error) {
	return nil, errors.New("resize is not supported")
}

func (p *Provider) Reinit(m *protocol.Machine) (*protocol.Artifact, error) {
	return nil, errors.New("reinitialize is not supported")
}
