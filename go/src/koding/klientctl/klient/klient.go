package klient

import (
	"errors"
	"io/ioutil"
	"koding/klient/remote/req"
	"koding/klientctl/list"
	"strings"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
)

// defaultKlientTimeout is a general timeout for klient communications.
const defaultKlientTimeout = 5 * time.Second

// Klient implements methods that klientctl uses when calling Klient, unmarshalling
// automatically into the proper methods.
type Klient struct {
	// The Teller is Klient's main "transport" for communication with the internal
	// Client.
	//
	// Why an interface here? Rather than Requiring a kite.Client specifically, the
	// Tell() method is the only thing required. As such, the Klient struct itself,
	// some older Transport structs, and pretty much any struct that talks to Kites
	// has this Tell method and Satisfies the interface.
	Teller interface {
		Tell(string, ...interface{}) (*dnode.Partial, error)
	}

	// Client is exposed (and via GetClient() mainly to allow the Klient struct
	// to be backwards compatible with non-Klient using methods.
	//
	// All actual communication is done via the Teller - this field purely exists
	// for the GetClient() method.
	Client *kite.Client
}

// NewKlient creates a Klient instance from the given kite.Client.
func NewKlient(c *kite.Client) *Klient {
	return &Klient{
		Client: c,
		Teller: c,
	}
}

// KlientOptions contains various fields for connecting to a klient.
type KlientOptions struct {
	// Address is the path to the Klient.
	Address string

	// KiteKeyPath is the full path to kite.key, which will be loaded and used
	// to authorize kdbin requests to Klient.
	KiteKeyPath string

	// Name, as passed to the first argument in `kite.New()`.
	Name string

	// Version, as passed to the second argument to `kite.New()`.
	Version string
}

// CreateKlientClient creates a kite to the klient specified by KlientOptions, and
// returns a Kite Client to talk to that Klient.
func CreateKlientClient(opts KlientOptions) (*kite.Client, error) {
	if opts.Version == "" {
		return nil, errors.New("CreateKlientClient: Version is required")
	}

	if opts.Address == "" {
		return nil, errors.New("CreateKlientClient: Address is required")
	}

	k := kite.New("klientctl", opts.Version)
	c := k.NewClient(opts.Address)

	// If a key path is declared, load it and setup auth.
	if opts.KiteKeyPath != "" {
		data, err := ioutil.ReadFile(opts.KiteKeyPath)
		if err != nil {
			return nil, err
		}

		c.Auth = &kite.Auth{
			Type: "kiteKey",
			Key:  strings.TrimSpace(string(data)),
		}
	}

	return c, nil
}

// NewDialedKlient creates a pre-dialed Klient instance
func NewDialedKlient(opts KlientOptions) (*Klient, error) {
	c, err := CreateKlientClient(opts)
	if err != nil {
		return nil, err
	}

	if err := c.Dial(); err != nil {
		return nil, err
	}

	return NewKlient(c), nil
}

func (k *Klient) Tell(methodName string, reqs ...interface{}) (*dnode.Partial, error) {
	if k.Teller == nil {
		return nil, errors.New("Missing Teller on Klient struct")
	}

	return k.Teller.Tell(methodName, reqs...)
}

// GetClient is a utility function for getting the underlying kite Client
// back from a Klient struct hidden behind an interface. Used mainly to
// interact with legacy code.
func (k *Klient) GetClient() *kite.Client {
	return k.Client
}

// RemoteList the current machines.
func (k *Klient) RemoteList() (list.KiteInfos, error) {
	res, err := k.Client.TellWithTimeout("remote.list", defaultKlientTimeout)
	if err != nil {
		return nil, err
	}

	var infos []list.KiteInfo
	if err := res.Unmarshal(&infos); err != nil {
		return nil, err
	}

	return infos, nil
}

// RemoteCache calls klient's remote.cache method.
//
// Note that due to how the remote/req library is setup, this function needs to
// take the callback as a separate argument for now. This will be improved
// in the future, in one way or another.
func (k *Klient) RemoteCache(r req.Cache, cb func(par *dnode.Partial)) error {
	cacheReq := struct {
		req.Cache
		Progress dnode.Function `json:"progress"`
	}{
		Cache:    r,
		Progress: dnode.Callback(cb),
	}

	// No response from cacheFolder currently.
	_, err := k.Tell("remote.cacheFolder", cacheReq)
	return err
}

// RemoteMountFolder calls klient's remote.mountFolder method. If there are
// any warnings, those are returned here.
func (k *Klient) RemoteMountFolder(r req.MountFolder) (string, error) {
	resp, err := k.Tell("remote.mountFolder", r)
	if err != nil {
		return "", err
	}

	var warning string
	// TODO: Ignore the nil unmarshal error, but return others.
	resp.Unmarshal(&warning)

	return warning, nil
}

// RemoteStatus calls klients remote.status method.
func (k *Klient) RemoteStatus(r req.Status) error {
	_, err := k.Tell("remote.status", r)
	return err
}

// RemoteMountInfo calls klients remote.mountInfo method.
func (k *Klient) RemoteMountInfo(r req.MountInfo) (req.MountFolder, error) {
	resp, err := k.Tell("remote.mountInfo", r)
	if err != nil {
		return req.MountFolder{}, err
	}

	var mountFolder req.MountFolder
	// TODO: Ignore the nil unmarshal error, but return others.
	resp.Unmarshal(&mountFolder)

	return mountFolder, nil
}
