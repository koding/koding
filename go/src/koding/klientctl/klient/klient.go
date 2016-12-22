// A library for easing the interaction with klient.
package klient

import (
	"errors"
	"io/ioutil"
	"strings"
	"time"

	"koding/klient/client"
	"koding/klient/command"
	"koding/klient/fs"
	"koding/klient/remote/req"
	"koding/klientctl/config"
	"koding/klientctl/list"

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

	// KiteKey is a content of kite.key, which is used for
	// authenticating kd with other klients.
	//
	// If not empty, this fields is used instead of KiteKeyPath.
	KiteKey string

	// Name, as passed to the first argument in `kite.New()`.
	Name string

	// Version, as passed to the second argument to `kite.New()`.
	Version string

	// Environment for the kite.Config.Environemnt.
	Environment string
}

// NewKlientOptions returns KlientOptions initialized to default values.
func NewKlientOptions() KlientOptions {
	return KlientOptions{
		Address:     config.Konfig.Endpoints.Klient.Private.String(),
		KiteKeyPath: config.Konfig.KiteKeyFile,
		KiteKey:     config.Konfig.KiteKey,
		Name:        config.Name,
		Version:     config.KiteVersion,
		Environment: config.Environment,
	}
}

// CreateKlientClient creates a kite with default KlientOptions and returns a
// Kite Client to talk to that Klient.
func CreateKlientWithDefaultOpts() (*kite.Client, error) {
	return CreateKlientClient(NewKlientOptions())
}

// CreateKlientClient creates a kite to the klient specified by KlientOptions.
// In most cases CreateKlientWithDefaultOpts should be used instead of this, ie
// this should be used only if you want to override KlientOptions.
func CreateKlientClient(opts KlientOptions) (*kite.Client, error) {
	if opts.Version == "" {
		return nil, errors.New("CreateKlientClient: Version is required")
	}

	if opts.Address == "" {
		return nil, errors.New("CreateKlientClient: Address is required")
	}

	k := kite.New(opts.Name, opts.Version)
	k.Config.Environment = opts.Environment
	c := k.NewClient(opts.Address)

	if opts.KiteKey != "" {
		c.Auth = &kite.Auth{
			Type: "kiteKey",
			Key:  opts.KiteKey,
		}
	} else if opts.KiteKeyPath != "" {
		// If a key path is declared, load it and setup auth.
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

// NewDefaultDialedKlient creates a pre-dialed Klient instance using default
// klient options.
func NewDefaultDialedKlient() (*Klient, error) {
	return NewDialedKlient(NewKlientOptions())
}

// NewDialedKlient creates a pre-dialed Klient instance. In most cases
// NewDefaultDialedKlient should be used instead of this, ie this should be used
// only if you want to override KlientOptions.
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
		Cache: r,
	}

	if cb != nil {
		cacheReq.Progress = dnode.Callback(cb)
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
func (k *Klient) RemoteMountInfo(mountName string) (req.MountInfoResponse, error) {
	r := req.MountInfo{MountName: mountName}
	resp, err := k.Tell("remote.mountInfo", r)
	if err != nil {
		return req.MountInfoResponse{}, err
	}

	var mountInfo req.MountInfoResponse
	// TODO: Ignore the nil unmarshal error, but return others.
	resp.Unmarshal(&mountInfo)

	return mountInfo, nil
}

// RemoteRemount calls klient's remote.remount method.
func (k *Klient) RemoteRemount(mountName string) error {
	r := req.Remount{MountName: mountName}
	_, err := k.Tell("remote.remount", r)
	return err
}

// RemoteExec calls the `remote.exec` method.
func (k *Klient) RemoteExec(machineName, c string) (command.Output, error) {
	var res command.Output
	req := req.Exec{Machine: machineName, Command: c}
	kRes, err := k.Tell("remote.exec", req)
	if err != nil {
		return res, err
	}

	return res, kRes.Unmarshal(&res)
}

func (k *Klient) RemoteReadDirectory(mountName, remotePath string) ([]fs.FileEntry, error) {
	r := req.ReadDirectoryOptions{
		Machine: mountName,
		ReadDirectoryOptions: fs.ReadDirectoryOptions{
			Path: remotePath,
		},
	}

	res, err := k.Tell("remote.readDirectory", r)
	if err != nil {
		return nil, err
	}

	resMap, err := res.Map()
	if err != nil {
		return nil, err
	}

	partial, ok := resMap["files"]
	if !ok {
		return nil, nil
	}

	filePartials, err := partial.Slice()
	if err != nil {
		return nil, err
	}

	files := make([]fs.FileEntry, len(filePartials))
	for i, p := range filePartials {
		var fe fs.FileEntry
		if err := p.Unmarshal(&fe); err != nil {
			return nil, err
		}
		files[i] = fe
	}

	return files, nil
}

// RemoteCurrentUsername calls klient's `remote.currentUsername` method
func (k *Klient) RemoteCurrentUsername(opts req.CurrentUsernameOptions) (string, error) {
	var username string

	kRes, err := k.Tell("remote.currentUsername", opts)
	if err != nil {
		return username, err
	}

	return username, kRes.Unmarshal(&username)
}

// RemoteGetPathSize calls the klient's `remote.getPathSize` method
func (k *Klient) RemoteGetPathSize(opts req.GetPathSizeOptions) (uint64, error) {
	var size uint64

	kRes, err := k.Tell("remote.getPathSize", opts)
	if err != nil {
		return size, err
	}

	return size, kRes.Unmarshal(&size)
}

func (k *Klient) LocalOpenFiles(files ...string) error {
	_, err := k.Tell("client.Publish", FilesEvent{
		PublishRequest: client.PublishRequest{EventName: "openFiles"},
		Files:          files,
	})

	return err
}
