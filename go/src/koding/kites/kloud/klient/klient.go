// Package klient provides an instance and abstraction to a remote klient kite.
// It is used to easily call methods of a klient kite
package klient

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"sync"
	"time"

	"koding/klient/fs"
	"koding/klient/machine/index"
	"koding/klient/os"
	"koding/klient/sshkeys"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
	"github.com/koding/logging"
)

var (
	ErrDialingFailed = errors.New("Dialing klient failed.")
	DefaultTimeout   = 60 * time.Second
	DefaultInterval  = 10 * time.Second
)

// KlientPool represents a pool of connected klients
type KlientPool struct {
	kite    *kite.Kite
	klients map[string]*Klient
	log     logging.Logger
	sync.Mutex
}

type Usage struct {
	// InactiveDuration reports the minimum duration since the latest activity.
	InactiveDuration time.Duration `json:"inactive_duration"`
}

// Klient represents a remote klient instance
type Klient struct {
	Client   *kite.Client
	kite     *kite.Kite
	Username string
	Timeout  time.Duration

	mu  sync.Mutex
	ctx context.Context
}

func (k *Klient) timeout() time.Duration {
	if k.Timeout != 0 {
		return k.Timeout
	}

	return DefaultTimeout
}

// ShareRequest is used for klient's klient.share,klient.unshare methods.
type ShareRequest struct {
	Username string
}

func NewPool(k *kite.Kite) *KlientPool {
	return &KlientPool{
		kite:    k,
		klients: make(map[string]*Klient),
		log:     logging.NewLogger("klientpool"),
	}
}

// Get returns a ready to use and connected klient from the pool.
func (k *KlientPool) Get(queryString string) (*Klient, error) {
	var klient *Klient
	var ok bool
	var err error

	k.Lock()
	defer k.Unlock()

	klient, ok = k.klients[queryString]
	if !ok {
		klient, err = Connect(k.kite, queryString)
		if err != nil {
			return nil, err
		}

		k.log.Info("Creating new klient connection to %s", queryString)
		k.klients[queryString] = klient

		// remove from the pool if we loose the connection
		klient.Client.OnDisconnect(func() {
			k.log.Info("Klient %s disconnected. removing from the pool", queryString)
			k.Delete(queryString)
			klient.Close()
		})
	} else {
		k.log.Debug("Fetching already connected klient (%s) from pool", queryString)
	}

	return klient, nil
}

// Delete removes the klient with the given queryString from the pool
func (k *KlientPool) Delete(queryString string) {
	k.Lock()
	defer k.Unlock()

	delete(k.klients, queryString)
}

// Exists checks whether the given queryString exists in Kontrol or not
func Exists(k *kite.Kite, queryString string) error {
	query, err := protocol.KiteFromString(queryString)
	if err != nil {
		return err
	}

	k.Log.Debug("Checking whether %s exists in Kontrol", queryString)

	// an error indicates a non existing klient or another error.
	_, err = k.GetKites(query.Query())
	if err != nil {
		return err
	}

	return nil
}

// Connect returns a new connected klient instance to the given queryString. The
// klient is ready to use. It's connected and needs to be closed once the task
// is finished with it.
func Connect(k *kite.Kite, queryString string) (*Klient, error) {
	return ConnectTimeout(k, queryString, 0)
}

// ConnectTimeout returns a new connected klient instance to the given
// queryString. The klient is ready to use. It's tries to connect for the given
// timeout duration
func ConnectTimeout(k *kite.Kite, queryString string, t time.Duration) (*Klient, error) {
	query, err := protocol.KiteFromString(queryString)
	if err != nil {
		return nil, err
	}

	k.Log.Debug("Connecting with timeout=%s to Klient: %s", t, queryString)

	kites, err := k.GetKites(query.Query())
	if err != nil {
		return nil, err
	}

	remoteKite := kites[0]

	err = remoteKite.DialTimeout(t)
	if err != nil {
		// If kite exists but dialing failed, we still return the *Klient
		// value, although not connected, in order to allow the caller
		// inspect the URL and eventually recover.
		err = ErrDialingFailed
	}

	k.Log.Debug("Dialing %q (%s) kite failed: %s", queryString, remoteKite.URL, err)

	return &Klient{
		kite:     k,
		Client:   remoteKite,
		Username: remoteKite.Username,
	}, err
}

func (k *Klient) URL() string {
	return k.Client.URL
}

func (k *Klient) IpAddress() (string, error) {
	u, err := url.Parse(k.Client.URL)
	if err != nil {
		return "", err
	}

	return u.Host, nil
}

func NewWithTimeout(k *kite.Kite, queryString string, t time.Duration) (klient *Klient, err error) {
	timeout := time.After(t)

	for {
		select {
		case <-timeout:
			if err == nil {
				err = errors.New("timed out connecting to klient: " + queryString)
			}

			return klient, err
		default:
			k.Log.Debug("Trying to connect to klient: %s", queryString)

			if klient, err = ConnectTimeout(k, queryString, DefaultInterval); err == nil {
				return klient, nil
			}

			time.Sleep(DefaultInterval)
		}
	}
}

func (k *Klient) Close() {
	k.Client.Close()
}

// Exec calls the os.exec method of remote klient.
func (k *Klient) Exec(req *os.ExecRequest) (*os.ExecResponse, error) {
	var resp os.ExecResponse

	if err := k.call("os.exec", req, &resp); err != nil {
		return nil, err
	}

	return &resp, nil
}

// Kill calls the os.kill method of remote klient.
func (k *Klient) Kill(req *os.KillRequest) (*os.KillResponse, error) {
	var resp os.KillResponse

	if err := k.call("os.kill", req, &resp); err != nil {
		return nil, err
	}

	return &resp, nil
}

func (k *Klient) call(method string, req, resp interface{}) error {
	type validator interface {
		Valid() error
	}

	if v, ok := req.(validator); ok {
		if err := v.Valid(); err != nil {
			return err
		}
	}

	r, err := k.Client.TellWithTimeout(method, k.timeout(), req)
	if err != nil {
		return err
	}

	if resp != nil {
		if err := r.Unmarshal(resp); err != nil {
			return err
		}
	}

	return nil
}

// Usage calls the usage method of remote and get's the result back
func (k *Klient) Usage() (*Usage, error) {
	resp, err := k.Client.TellWithTimeout("klient.usage", k.timeout())
	if err != nil {
		return nil, err
	}

	var usg Usage
	if err := resp.Unmarshal(&usg); err != nil {
		return nil, err
	}

	return &usg, nil
}

// Ping checks if the given klient response with "pong" to the "ping" we send.
// A nil error means a successful pong result.
func (k *Klient) Ping() error {
	resp, err := k.Client.TellWithTimeout("kite.ping", 10*time.Second)
	if err != nil {
		return err
	}

	out, err := resp.String()
	if err != nil {
		return err
	}

	if out == "pong" {
		return nil
	}

	return fmt.Errorf("wrong response %s", out)
}

// PingTimeout issues a ping requests for the duration t. It returns
// with nil error as soon as a ping requests succeeds.
func (k *Klient) PingTimeout(t time.Duration) (err error) {
	timeout := time.After(t)
	ticker := time.NewTicker(DefaultInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			if err = k.Ping(); err == nil {
				return nil
			}

		case <-timeout:
			return err
		}
	}
}

// AddUser adds the given username to the klient's permission list. Once added
// the user is able to make requests to Klient
func (k *Klient) AddUser(username string) error {
	resp, err := k.Client.TellWithTimeout("klient.share", k.timeout(), &ShareRequest{username})
	if err != nil {
		return err
	}

	out, err := resp.String()
	if err != nil {
		return err
	}

	if out == "shared" {
		return nil
	}

	return fmt.Errorf("wrong response %s", out)
}

// RemoveUser removes the given username from the klient's permission list.
// Once removed the user is not able to make requests to Klient anymore.
func (k *Klient) RemoveUser(username string) error {
	resp, err := k.Client.TellWithTimeout("klient.unshare", k.timeout(), &ShareRequest{username})
	if err != nil {
		return err
	}

	out, err := resp.String()
	if err != nil {
		return err
	}

	if out == "unshared" {
		return nil
	}

	return fmt.Errorf("wrong response %s", out)
}

// Username returns remote machine current username.
func (k *Klient) CurrentUser() (string, error) {
	resp, err := k.Client.TellWithTimeout("os.currentUsername", k.timeout())
	if err != nil {
		return "", err
	}

	var username string
	if err := resp.Unmarshal(&username); err != nil {
		return "", err
	}

	return username, nil
}

// Abs returns absolute representation of given path.
func (k *Klient) Abs(path string) (string, bool, bool, error) {
	req := fs.AbsRequest{
		Path: path,
	}

	var resp fs.AbsResponse
	if err := k.call("fs.abs", req, &resp); err != nil {
		return "", false, false, err
	}

	return resp.AbsPath, resp.IsDir, resp.Exist, nil
}

// SSHAddKeys adds SSH public keys to user's authorized_keys file.
func (k *Klient) SSHAddKeys(username string, keys ...string) error {
	addopts := sshkeys.AddOptions{
		Username: username,
		Keys:     keys,
	}

	_, err := k.Client.TellWithTimeout("sshkeys.add", k.timeout(), addopts)
	if err != nil {
		// Ignore errors about duplicate keys since we're adding on each run.
		if strings.Contains(err.Error(), "cannot add duplicate ssh key") {
			return nil
		}

		return err
	}

	// TODO(ppknap): currently sshkeys.add method can return either nil or true
	// as its response. Add proper support for this.
	return nil
}

// MountHeadIndex returns the number and the overall size of files in a given
// remote directory.
func (k *Klient) MountHeadIndex(path string) (absPath string, count int, diskSize int64, err error) {
	req := index.Request{
		Path: path,
	}

	raw, err := k.Client.TellWithTimeout("machine.index.head", k.timeout(), req)
	if err != nil {
		return "", 0, 0, err
	}

	resp := index.HeadResponse{}
	if err := raw.Unmarshal(&resp); err != nil {
		return "", 0, 0, err
	}

	return resp.AbsPath, resp.Count, resp.DiskSize, nil
}

// MountGetIndex returns an index that describes the current state of remote
// directory.
func (k *Klient) MountGetIndex(path string) (*index.Index, error) {
	req := index.Request{
		Path: path,
	}

	raw, err := k.Client.TellWithTimeout("machine.index.get", k.timeout(), req)
	if err != nil {
		return nil, err
	}

	resp := index.GetResponse{
		Index: index.NewIndex(),
	}
	if err := raw.Unmarshal(&resp); err != nil {
		return nil, err
	}

	if resp.Index == nil {
		return nil, errors.New("retrieved index is nil")
	}

	return resp.Index, nil
}

// SetContext sets provided context to Klient.
func (k *Klient) SetContext(ctx context.Context) {
	k.mu.Lock()
	defer k.mu.Unlock()

	k.ctx = ctx
}

// Context returns Klient's context.
func (k *Klient) Context() context.Context {
	k.mu.Lock()
	defer k.mu.Unlock()

	return k.ctx
}
