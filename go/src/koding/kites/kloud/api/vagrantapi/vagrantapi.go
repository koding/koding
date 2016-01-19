package vagrantapi

import (
	"fmt"
	"strings"
	"time"

	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/kite/protocol"
	"github.com/koding/logging"
)

// TODO(rjeczalik): use klient.KlientPool for caching connected kites with reconnect

const (
	magicEnd           = "guCnvNVedAQT8DiNpcP3pVqzseJvLY"
	defaultDialTimeout = 30 * time.Second
	defaultTimeout     = 10 * time.Minute
)

// State* represent consts for vagrantutil box states.
const (
	StatePowerOff   = "poweroff"
	StatePreparing  = "preparing"
	StateRunning    = "running"
	StateNotCreated = "notcreated"
	StateAborted    = "aborted"
	StateSaved      = "saved"
)

// Create represents vagrant.create request and response.
type Create struct {
	FilePath      string // always absolute for response values
	ProvisionData string // base64-json-encoded userdata.Value
	Hostname      string // hostname of the box
	Box           string // box type
	Memory        int    // memory in MiB
	Cpus          int    // number of cores
	CustomScript  string // custom sh script, plain text
}

// Command represents vagrant.{up,halt,destroy} requests.
type Command struct {
	FilePath string         // can be relative or absolute
	Watch    dnode.Function // internal detail, to receive command output, ended with a magic value
}

// Status response values for vagrant.{list,status} requests.
type Status struct {
	FilePath string
	State    string
}

// MachineState maps the State field to machinestate.State value.
func (s *Status) MachineState() machinestate.State {
	switch s.State {
	case StatePowerOff, StateAborted:
		return machinestate.Stopped
	case StateSaved:
		return machinestate.Snapshotting
	case StatePreparing:
		return machinestate.Building
	case StateRunning:
		return machinestate.Running
	case StateNotCreated:
		return machinestate.NotInitialized
	default:
		return machinestate.Unknown
	}
}

// Klient represents a client for vagrantkite. Spelled with a K, because we
// can.
type Klient struct {
	Kite *kite.Kite
	Log  logging.Logger

	DialTimeout time.Duration // 30s by default
	Timeout     time.Duration // 10m by default
}

func (k *Klient) dialTimeout() time.Duration {
	if k.DialTimeout != 0 {
		return k.DialTimeout
	}
	return defaultDialTimeout
}

func (k *Klient) timeout() time.Duration {
	if k.Timeout != 0 {
		return k.Timeout
	}
	return defaultTimeout
}

func (k *Klient) send(queryString, method string, req, resp interface{}) error {
	queryString = protoID(queryString)

	k.Log.Debug("calling %q method on %q with %+v", method, queryString, req)

	kref, err := klient.ConnectTimeout(k.Kite, queryString, k.dialTimeout())
	if err != nil {
		return err
	}
	defer kref.Close()

	r, err := kref.Client.TellWithTimeout(method, k.timeout(), req)
	if err != nil {
		return err
	}

	if err := r.Unmarshal(resp); err != nil {
		return err
	}

	k.Log.Debug("received %+v response from %q (%q)", resp, method, queryString)

	return nil
}

func (k *Klient) cmd(queryString, method, boxPath string) error {
	queryString = protoID(queryString)

	k.Log.Debug("calling %q command on %q with %q", method, queryString, boxPath)

	kref, err := klient.ConnectTimeout(k.Kite, queryString, k.dialTimeout())
	if err != nil {
		return err
	}

	done := make(chan struct{})

	watch := dnode.Callback(func(r *dnode.Partial) {
		msg := r.One().MustString()
		k.Log.Debug("%s: %s", method, msg)
		if msg == magicEnd {
			close(done)
		}
	})

	req := &Command{
		FilePath: boxPath,
		Watch:    watch,
	}

	if _, err = kref.Client.TellWithTimeout(method, k.timeout(), req); err != nil {
		return err
	}

	select {
	case <-done:
		return nil
	case <-time.After(k.timeout()):
		return fmt.Errorf("timed out calling %q on %q", method, queryString)
	}
}

func protoID(queryString string) string {
	if strings.HasPrefix(queryString, "/") {
		return queryString
	}
	return protocol.Kite{ID: queryString}.String()
}

// Create calls vagrant.create method on a kite given by the queryString.
func (k *Klient) Create(queryString string, req *Create) (resp *Create, err error) {
	resp = &Create{}

	if err := k.send(queryString, "vagrant.create", req, resp); err != nil {
		return nil, err
	}

	return resp, nil
}

// List calls vagrant.list method on a kite given by the queryString.
func (k *Klient) List(queryString string) ([]*Status, error) {
	req := struct{ FilePath string }{"."} // workaround for TMS-2106
	resp := make([]*Status, 0)

	if err := k.send(queryString, "vagrant.list", req, &resp); err != nil {
		return nil, err
	}

	return resp, nil
}

// Status calls vagrant.status method on a kite given by the queryString.
func (k *Klient) Status(queryString, boxPath string) (*Status, error) {
	resp := &Status{}
	req := struct {
		FilePath string
	}{boxPath}

	if err := k.send(queryString, "vagrant.status", req, resp); err != nil {
		return nil, err
	}

	resp.State = strings.ToLower(resp.State) // workaround for TMS-2106

	return resp, nil
}

// Destroy calls vagrant.destroy method on a kite given by the queryString.
func (k *Klient) Destroy(queryString, boxPath string) error {
	return k.cmd(queryString, "vagrant.destroy", boxPath)
}

// Up calls vagrant.up method on a kite given by the queryString.
func (k *Klient) Up(queryString, boxPath string) error {
	return k.cmd(queryString, "vagrant.up", boxPath)
}

// Halt calls vagrant.halt method on a kite given by the queryString.
func (k *Klient) Halt(queryString, boxPath string) error {
	return k.cmd(queryString, "vagrant.halt", boxPath)
}

// Version calls vagrant.version method on a kite given by the queryString.
func (k *Klient) Version(queryString string) (string, error) {
	req := struct{ FilePath string }{"."} // workaround for TMS-2106
	var resp string

	if err := k.send(queryString, "vagrant.version", req, &resp); err != nil {
		return "", err
	}

	return resp, nil
}
