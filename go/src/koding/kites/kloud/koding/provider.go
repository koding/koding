package koding

import (
	"fmt"
	"time"

	"koding/db/mongodb"
	"koding/kites/kloud/klient"

	"github.com/koding/kite"
	"github.com/koding/kloud"
	amazonClient "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/amazon"
	"github.com/koding/logging"
)

var (
	DefaultRegion = "us-east-1"

	// Credential belongs to the `koding-kloud` user in AWS IAM's
	kodingCredential = map[string]interface{}{
		"access_key": "AKIAIDPT7E2UHZHT2CXQ",
		"secret_key": "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",
	}
)

const (
	ProviderName = "koding"
)

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

	// Contains the users home directory to be added into a image
	TemplateDir string

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
}

func (p *Provider) NewClient(machine *protocol.Machine) (*amazon.AmazonClient, error) {
	username := machine.Builder["username"].(string)

	a := &amazon.AmazonClient{
		Log: p.Log,
		Push: func(msg string, percentage int, state machinestate.State) {
			p.Log.Info("[%s] %s (username: %s)", machine.MachineId, msg, username)

			machine.Eventer.Push(&eventer.Event{
				Message:    msg,
				Status:     state,
				Percentage: percentage,
			})
		},
	}

	var err error

	machine.Builder["region"] = DefaultRegion

	a.Amazon, err = amazonClient.New(kodingCredential, machine.Builder)
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

func (p *Provider) Name() string {
	return ProviderName
}

func (p *Provider) Start(opts *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(opts)
	if err != nil {
		return nil, err
	}

	artifact, err := a.Start()
	if err != nil {
		return nil, err
	}

	machineData, ok := opts.CurrentData.(*Machine)
	if !ok {
		return nil, fmt.Errorf("current data is malformed: %v", opts.CurrentData)
	}

	a.Push("Initializing domain instance", 65, machinestate.Starting)

	/////// ROUTE 53 /////////////////
	username := opts.Builder["username"].(string)

	if err := p.UpdateDomain(artifact.IpAddress, machineData.Domain, username); err != nil {
		return nil, err
	}

	a.Log.Info("[%s] Updating user domain tag '%s' of instance '%s'",
		opts.MachineId, machineData.Domain, artifact.InstanceId)
	if err := a.AddTag(artifact.InstanceId, "koding-domain", machineData.Domain); err != nil {
		return nil, err
	}

	artifact.DomainName = machineData.Domain
	///// ROUTE 53 /////////////////

	a.Push("Checking remote machine", 90, machinestate.Starting)
	p.Log.Info("[%s] Connecting to remote Klient instance", opts.MachineId)
	klientRef, err := klient.NewWithTimeout(p.Kite, machineData.QueryString, time.Minute*1)
	if err != nil {
		p.Log.Warning("Connecting to remote Klient instance err: %s", err)
	} else {
		defer klientRef.Close()
		p.Log.Info("[%s] Sending a ping message", opts.MachineId)
		if err := klientRef.Ping(); err != nil {
			p.Log.Warning("Sending a ping message err:", err)
		}
	}

	return artifact, nil
}

func (p *Provider) Stop(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	err = a.Stop()
	if err != nil {
		return err
	}

	/////// ROUTE 53 /////////////////
	username := opts.Builder["username"].(string)

	machineData, ok := opts.CurrentData.(*Machine)
	if !ok {
		return fmt.Errorf("current data is malformed: %v", opts.CurrentData)
	}

	a.Push("Initializing domain instance", 65, machinestate.Stopping)

	if err := validateDomain(machineData.Domain, username, p.HostedZone); err != nil {
		return err
	}

	a.Push("Deleting domain", 75, machinestate.Stopping)
	if err := p.DNS.DeleteDomain(machineData.Domain, machineData.IpAddress); err != nil {
		return err
	}

	///// ROUTE 53 /////////////////

	a.Push("Updating ip address", 85, machinestate.Stopping)
	if err := p.Update(opts.MachineId, &kloud.StorageData{
		Type: "stop",
		Data: map[string]interface{}{
			"ipAddress": "",
		},
	}); err != nil {
		p.Log.Error("[stop] storage update of essential data was not possible: %s", err.Error())
	}

	return nil
}

func (p *Provider) Restart(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	return a.Restart()
}

func (p *Provider) Destroy(opts *protocol.Machine) error {
	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	err = a.Destroy()
	if err != nil {
		return err
	}

	/////// ROUTE 53 /////////////////

	username := opts.Builder["username"].(string)

	machineData, ok := opts.CurrentData.(*Machine)
	if !ok {
		return fmt.Errorf("current data is malformed: %v", opts.CurrentData)
	}

	if err := validateDomain(machineData.Domain, username, p.HostedZone); err != nil {
		return err
	}

	a.Push("Checking domain", 75, machinestate.Terminating)
	// Check if the record exist, it can be deleted via stop, therefore just
	// return lazily
	_, err = p.DNS.Domain(machineData.Domain)
	if err == ErrNoRecord {
		return nil
	}

	// If it's something else just return it
	if err != nil {
		return err
	}

	a.Push("Deleting domain", 85, machinestate.Terminating)
	if err := p.DNS.DeleteDomain(machineData.Domain, machineData.IpAddress); err != nil {
		return err
	}

	///// ROUTE 53 /////////////////
	return nil
}
