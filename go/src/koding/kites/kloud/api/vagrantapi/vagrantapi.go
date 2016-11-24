package vagrantapi

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/utils"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/logging"
)

// TODO(rjeczalik): use klient.KlientPool for caching connected kites with reconnect

const (
	defaultDialTimeout = 30 * time.Second
	defaultTimeout     = 10 * time.Minute
)

// State represent consts for vagrantutil box states.
type State string

const (
	StatePowerOff   = State("poweroff")
	StatePreparing  = State("preparing")
	StateRunning    = State("running")
	StateNotCreated = State("notcreated")
	StateAborted    = State("aborted")
	StateSaved      = State("saved")
)

// ForwardedPort represents a single config.vm.network "forwarded_port" rule
// in a Vagrantfile.
type ForwardedPort struct {
	GuestPort int `json:"guest,omitempty"`
	HostPort  int `json:"host,omitempty"`
}

// Create represents vagrant.create request and response.
type Create struct {
	FilePath       string           // always absolute for response values
	ProvisionData  string           // base64-json-encoded userdata.Value
	Hostname       string           // hostname of the box
	Username       string           // owner of the box
	Box            string           // box type
	Memory         int              // memory in MiB
	Cpus           int              // number of cores
	CustomScript   string           // custom sh script, plain text
	HostURL        string           // host kite URL
	ForwardedPorts []*ForwardedPort `json:"forwarded_ports,omitempty"`
	Debug          bool             // enable klient/vagrant debug logging
}

// Command represents vagrant.{up,halt,destroy} requests.
type Command struct {
	FilePath  string // can be relative or absolute
	Success   dnode.Function
	Failure   dnode.Function
	Output    dnode.Function
	Heartbeat dnode.Function
}

// Status response values for vagrant.{list,status} requests.
type Status struct {
	FilePath string `json:"filePath"`
	State    State  `json:"state"`
	Error    string `json:"error"`
}

// MachineState maps the State field to machinestate.State value.
func (s State) MachineState() machinestate.State {
	switch s {
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

// Klient represents a client for vagrant. Spelled with a K, because we
// can.
type Klient struct {
	Kite  *kite.Kite
	Log   logging.Logger
	Debug bool

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

func (k *Klient) send(queryString, method string, req, resp interface{}) (string, error) {
	queryString, err := utils.QueryString(queryString)
	if err != nil {
		return "", err
	}

	k.Log.Debug("calling %q method on %q with %+v", method, queryString, req)

	kref, err := klient.ConnectTimeout(k.Kite, queryString, k.dialTimeout())
	if err != nil {
		k.Log.Debug("connecting to %q klient failed: %s", queryString, err)

		return "", err
	}
	defer kref.Close()

	r, err := kref.Client.TellWithTimeout(method, k.timeout(), req)
	if err != nil {
		k.Log.Debug("sending request to %q klient failed: %s", queryString, err)

		return "", err
	}

	if err := r.Unmarshal(resp); err != nil {
		return "", errors.New("reading response from klient failed: " + err.Error())
	}

	k.Log.Debug("received %+v response from %q (%q)", resp, method, queryString)

	return kref.URL(), nil
}

func (k *Klient) cmd(queryString, method, boxPath string) error {
	queryString, err := utils.QueryString(queryString)
	if err != nil {
		return err
	}

	k.Log.Debug("calling %q command on %q with %q", method, queryString, boxPath)

	kref, err := klient.ConnectTimeout(k.Kite, queryString, k.dialTimeout())
	if err != nil {
		k.Log.Debug("connecting to %q klient failed: %s", queryString, err)

		return err
	}

	done := make(chan error, 1)

	success := dnode.Callback(func(*dnode.Partial) {
		done <- nil
	})

	failure := dnode.Callback(func(r *dnode.Partial) {
		msg, err := r.One().String()
		if err != nil {
			err = errors.New("unknown failure")
		} else {
			err = errors.New(msg)
		}
		done <- err
	})

	lost := make(chan struct{})
	beat := make(chan struct{})
	stop := make(chan struct{})
	defer close(stop)

	go func() {
		// Heartbeat timer is initially stopped since at this
		// point we do not know whether klient supports heartbeats.
		// On first heartbeat we activate the timer and set the ch.
		var (
			t  *time.Timer
			ch <-chan time.Time
		)

		for {
			select {
			case <-stop:
				return
			case <-ch:
				lost <- struct{}{}
			case <-beat:
				if t == nil {
					t = time.NewTimer(defaultDialTimeout)
					ch = t.C
					defer t.Stop()
				}

				t.Reset(defaultDialTimeout)
			}
		}
	}()

	heartbeat := dnode.Callback(func(r *dnode.Partial) {
		beat <- struct{}{}
	})

	req := &Command{
		FilePath:  boxPath,
		Success:   success,
		Failure:   failure,
		Heartbeat: heartbeat,
	}

	if k.Debug {
		log := k.Log.New(method)
		req.Output = dnode.Callback(func(r *dnode.Partial) {
			log.Debug("%s", r.One().MustString())
		})
	}

	if _, err = kref.Client.TellWithTimeout(method, k.timeout(), req); err != nil {
		return errors.New("sending request to klient failed: " + err.Error())
	}

	select {
	case err := <-done:
		return err
	case <-time.After(k.timeout()):
		return fmt.Errorf("timed out calling %q on %q", method, queryString)
	case <-lost:
		return errors.New("connection to your KD Daemon was lost due to inactivity")
	}
}

// Create calls vagrant.create method on a kite given by the queryString.
func (k *Klient) Create(queryString string, req *Create) (resp *Create, err error) {
	resp = &Create{}

	// Share the host kite with quest kite.
	if req.Username != "" {
		share := map[string]interface{}{
			"username":  req.Username,
			"permanent": true,
		}

		if _, err := k.send(queryString, "klient.share", share, nil); err != nil {
			if !strings.Contains(err.Error(), "user is already in the shared list") {
				k.Log.Error("failed to share %q with %q: %s", queryString, req.Username, err)
			}
		}
	}

	url, err := k.send(queryString, "vagrant.create", req, resp)
	if err != nil {
		return nil, err
	}

	resp.HostURL = url

	return resp, nil
}

// List calls vagrant.list method on a kite given by the queryString.
func (k *Klient) List(queryString string) ([]*Status, error) {
	req := struct{ FilePath string }{"."} // workaround for TMS-2106
	resp := make([]*Status, 0)

	if _, err := k.send(queryString, "vagrant.list", req, &resp); err != nil {
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

	if _, err := k.send(queryString, "vagrant.status", req, resp); err != nil {
		return nil, err
	}

	resp.State = State(strings.ToLower(string(resp.State))) // workaround for TMS-2106

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
	req := &struct {
		FilePath string `json:"filePath"`
		Name     string `json:"name"`
	}{
		".",
		"vagrant",
	}
	var resp = &struct {
		Vagrant string `json:"vagrant"`
	}{}

	_, err := k.send(queryString, "vagrant.version", req, resp)
	if err != nil {
		// TODO(rjeczalik): koding/kite wraps *json.UnmarshalTypeError
		// so we need to compare error string instead - fix it
		if strings.Contains(err.Error(), "json: cannot unmarshal") {
			return "", errors.New(`Your KD is outdated. Please run "sudo kd update" to upgrade and retry.`)
		}

		return "", err
	}

	return resp.Vagrant, nil
}
