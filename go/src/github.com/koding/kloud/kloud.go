package kloud

import (
	"io/ioutil"
	"log"

	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/idlock"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/digitalocean"
	"github.com/koding/kloud/provider/openstack"

	"github.com/koding/kite"
	"github.com/koding/logging"
)

const (
	VERSION = "0.0.1"
	NAME    = "kloud"
)

type Kloud struct {
	Log  logging.Logger
	Kite *kite.Kite

	Storage   Storage
	Eventers  map[string]eventer.Eventer
	Providers map[string]protocol.Provider

	idlock *idlock.IdLock

	Name        string
	Version     string
	Region      string
	Environment string
	Port        int

	// needed for signing/generating kite tokens
	KontrolPublicKey  string
	KontrolPrivateKey string
	KontrolURL        string

	// S3 related stuff, like signing url, downloading list and so on.
	Bucket *Bucket

	Debug bool
}

func (k *Kloud) NewKloud() *kite.Kite {
	k.Name = NAME
	k.Version = VERSION

	k.idlock = idlock.New()

	k.Kite = kite.New(k.Name, k.Version)

	// read kontrolURL from kite.key if it doesn't exist.
	if k.KontrolURL == "" {
		k.KontrolURL = k.Kite.Config.KontrolURL.String()
	}

	if k.Log == nil {
		k.Log = logging.NewLogger(NAME)
	}

	if k.Eventers == nil {
		k.Eventers = make(map[string]eventer.Eventer)
	}

	k.Kite.Config.Region = k.Region
	k.Kite.Config.Port = k.Port

	k.ControlFunc("build", k.build)
	k.ControlFunc("start", k.start)
	k.ControlFunc("stop", k.stop)
	k.ControlFunc("restart", k.restart)
	k.ControlFunc("destroy", k.destroy)
	k.ControlFunc("info", k.info)
	k.Kite.HandleFunc("event", k.event)

	k.InitializeProviders()

	return k.Kite
}

func (k *Kloud) InitializeProviders() {
	// Our digitalocean api uses lots of logs, the only way to supress them is
	// to disable std log package.
	log.SetOutput(ioutil.Discard)

	k.Providers = map[string]protocol.Provider{
		"digitalocean": &digitalocean.Provider{
			Log:         createLogger("digitalocean", k.Debug),
			Region:      k.Region,
			Environment: k.Kite.Config.Environment,
		},
		"rackspace": &openstack.Provider{
			Log:          createLogger("rackspace", k.Debug),
			Region:       k.Region,
			Environment:  k.Kite.Config.Environment,
			AuthURL:      "https://identity.api.rackspacecloud.com/v2.0",
			ProviderName: "rackspace",
		},
	}
}

func (k *Kloud) GetProvider(providerName string) (protocol.Provider, error) {
	provider, ok := k.Providers[providerName]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	return provider, nil
}
