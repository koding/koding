package koding

import (
	"fmt"
	"sync"
	"time"

	"koding/db/mongodb"

	amazonClient "koding/kites/kloud/api/amazon"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"koding/kites/kloud/provider/amazon"

	"github.com/koding/kite"
	"github.com/koding/logging"
)

var (
	DefaultRegion = "us-east-1"

	// Credential belongs to the `koding-kloud` user in AWS IAM's
	kodingCredential = map[string]interface{}{
		"access_key": "AKIAIKAVWAYVSMCW4Z5A",
		"secret_key": "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",
	}
)

const (
	ProviderName = "koding"
)

type pushValues struct {
	Start, Finish int
}

// Provider implements the kloud packages Storage, Builder and Controller
// interface
type Provider struct {
	Kite         *kite.Kite
	Session      *mongodb.MongoDB
	AssigneeName string
	Log          logging.Logger
	Push         func(string, int, machinestate.State)

	// A flag saying if user permissions should be ignored
	// store negation so default value is aligned with most common use case
	Test bool

	// DNS is used to create/update domain recors
	DNS        *DNS
	HostedZone string

	Bucket *Bucket

	KontrolURL        string
	KontrolPrivateKey string
	KontrolPublicKey  string

	// If available a key pair with the given public key and name should be
	// deployed to the machine, the corresponding PrivateKey should be returned
	// in the ProviderArtifact. Some providers such as Amazon creates
	// publicKey's on the fly and generates the privateKey themself.
	PublicKey  string `structure:"publicKey"`
	PrivateKey string `structure:"privateKey"`
	KeyName    string `structure:"keyName"`

	// A set of connected, ready to use klients
	KlientPool *klient.KlientPool

	// A set of machines that defines machines who's klient kites are not
	// running. The timer is used to stop the machines after 30 minutes
	// inactivity.
	InactiveMachines   map[string]*time.Timer
	InactiveMachinesMu sync.Mutex

	PlanChecker func(*protocol.Machine) (Checker, error)
	PlanFetcher func(*protocol.Machine) (Plan, error)
}

func (p *Provider) NewClient(m *protocol.Machine) (*amazon.AmazonClient, error) {
	a := &amazon.AmazonClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("[%s] %s (username: %s)", m.Id, msg, m.Username)

			m.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
	}

	var err error

	m.Builder["region"] = DefaultRegion

	a.Amazon, err = amazonClient.New(kodingCredential, m.Builder)
	if err != nil {
		return nil, fmt.Errorf("koding-amazon err: %s", err)
	}

	// needed to deploy during build
	a.Builder.KeyPair = p.KeyName

	// needed to create the keypair if it doesn't exist
	a.Builder.PublicKey = p.PublicKey
	a.Builder.PrivateKey = p.PrivateKey

	// lazy init
	if p.DNS == nil {
		if err := p.InitDNS(a.Creds.AccessKey, a.Creds.SecretKey); err != nil {
			return nil, err
		}
	}

	return a, nil
}

func (p *Provider) Start(m *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	artifact, err := a.Start(true)
	if err != nil {
		return nil, err
	}

	a.Push("Initializing domain instance", 65, machinestate.Starting)
	if err := p.UpdateDomain(artifact.IpAddress, m.Domain.Name, m.Username); err != nil {
		return nil, err
	}

	a.Log.Info("[%s] Updating user domain tag '%s' of instance '%s'",
		m.Id, m.Domain.Name, artifact.InstanceId)
	if err := a.AddTag(artifact.InstanceId, "koding-domain", m.Domain.Name); err != nil {
		return nil, err
	}

	artifact.DomainName = m.Domain.Name

	a.Push("Checking remote machine", 90, machinestate.Starting)
	if p.IsKlientReady(m.QueryString) {
		p.Log.Info("[%s] klient is ready.", m.Id)
	} else {
		p.Log.Warning("[%s] klient is not ready. I couldn't connect to it.", m.Id)
	}

	return artifact, nil
}

func (p *Provider) Stop(m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	err = a.Stop(true)
	if err != nil {
		return err
	}

	a.Push("Initializing domain instance", 65, machinestate.Stopping)

	if err := validateDomain(m.Domain.Name, m.Username, p.HostedZone); err != nil {
		return err
	}

	a.Push("Deleting domain", 85, machinestate.Stopping)
	if err := p.DNS.DeleteDomain(m.Domain.Name, m.IpAddress); err != nil {
		return err
	}

	return nil
}

func (p *Provider) Restart(m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return a.Restart()
}

func (p *Provider) Reinit(m *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	if err := p.destroy(a, m, &pushValues{Start: 10, Finish: 40}); err != nil {
		return nil, err
	}

	return p.build(a, m, &pushValues{Start: 40, Finish: 90})
}

func (p *Provider) Destroy(m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return p.destroy(a, m, &pushValues{Start: 10, Finish: 90})
}

func (p *Provider) destroy(a *amazon.AmazonClient, m *protocol.Machine, v *pushValues) error {
	// means if final is 40 our destroy method below will be push at most up to
	// 32.

	middleVal := float64(v.Finish) * (8.0 / 10.0)

	err := a.Destroy(v.Start, int(middleVal))
	if err != nil {
		return err
	}

	if err := validateDomain(m.Domain.Name, m.Username, p.HostedZone); err != nil {
		return err
	}

	// increase one tick but still don't let it reach the final value
	lastVal := float64(v.Finish) * (9.0 / 10.0)

	a.Push("Checking domain", int(lastVal), machinestate.Terminating)
	// Check if the record exist, it can be deleted via stop, therefore just
	// return lazily
	_, err = p.DNS.Domain(m.Domain.Name)
	if err == ErrNoRecord {
		return nil
	}

	// If it's something else just return it
	if err != nil {
		return err
	}

	a.Push("Deleting domain", v.Finish, machinestate.Terminating)
	if err := p.DNS.DeleteDomain(m.Domain.Name, m.IpAddress); err != nil {
		return err
	}

	return nil

}
