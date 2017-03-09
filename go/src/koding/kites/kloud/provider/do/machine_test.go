package do

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"
	"testing"

	"koding/db/models"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"

	"github.com/digitalocean/godo"
	"golang.org/x/net/context"
)

func TestNewMachine(t *testing.T) {
	bm := newDoBaseMachine(12345)
	_, err := newMachine(bm)
	if err != nil {
		t.Fatal(err)
	}
}

func TestEmptyDropletID(t *testing.T) {
	bm := newDoBaseMachine(0)
	machine, err := newMachine(bm)
	if err != nil {
		t.Fatal(err)
	}

	_, err = machine.Start(context.Background())
	if err != ErrInvalidDropletID {
		t.Errorf("Droplet ID should return %s, got %s", ErrInvalidDropletID, err)
	}
}

func TestMachineStart(t *testing.T) {
	dropletID := 12345
	bm := newDoBaseMachine(dropletID)
	machine, err := newMachine(bm)
	if err != nil {
		t.Fatal(err)
	}

	handler := func(w http.ResponseWriter, r *http.Request) {
		action := &godo.Action{
			ID:     dropletID,
			Status: "completed",
		}

		_ = json.NewEncoder(w).Encode(newRootAction(action))
	}

	err = withClient(http.HandlerFunc(handler), func(client *godo.Client) error {
		m, ok := machine.(*Machine)
		if !ok {
			return fmt.Errorf("can't type assert %T to *Machine", machine)
		}

		m.client = client

		ctx := context.Background()
		_, err := m.Start(ctx)
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestMachineStop(t *testing.T) {
	dropletID := 12345
	bm := newDoBaseMachine(dropletID)
	machine, err := newMachine(bm)
	if err != nil {
		t.Fatal(err)
	}

	handler := func(w http.ResponseWriter, r *http.Request) {
		action := &godo.Action{
			ID:     dropletID,
			Status: "completed",
		}

		_ = json.NewEncoder(w).Encode(newRootAction(action))
	}

	err = withClient(http.HandlerFunc(handler), func(client *godo.Client) error {
		m, ok := machine.(*Machine)
		if !ok {
			return fmt.Errorf("can't type assert %T to *Machine", machine)
		}

		m.client = client

		ctx := context.Background()
		_, err := m.Stop(ctx)
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
}

func TestMachineInfo(t *testing.T) {
	tests := []struct {
		name       string
		dropletID  int // by default initialized
		statusCode int // by default 200
		status     string
		state      machinestate.State
	}{
		{
			name:   "new droplet",
			status: "new",
			state:  machinestate.Starting,
		},
		{
			name:   "running droplet",
			status: "active",
			state:  machinestate.Running,
		},
		{
			name:   "stopped droplet",
			status: "off",
			state:  machinestate.Stopped,
		},
		{
			name:   "destroyed droplet",
			status: "archive",
			state:  machinestate.Terminated,
		},
		{
			name:       "not available droplet",
			state:      machinestate.NotInitialized,
			statusCode: http.StatusNotFound,
		},
		{
			name:       "server not responding",
			state:      machinestate.Unknown,
			statusCode: http.StatusInternalServerError,
		},
		{
			name:      "droplet id malformed",
			dropletID: -1,
			state:     machinestate.Unknown,
		},
	}

	for _, test := range tests {
		// capture range variable here
		test := test
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			dropletID := 12345
			if test.dropletID != 0 {
				dropletID = 0
			}

			bm := newDoBaseMachine(dropletID)
			machine, err := newMachine(bm)
			if err != nil {
				t.Fatal(err)
			}

			handler := func(w http.ResponseWriter, r *http.Request) {
				droplet := &godo.Droplet{
					ID:     dropletID,
					Status: test.status,
				}

				if test.statusCode != 0 {
					w.WriteHeader(test.statusCode)
				}
				_ = json.NewEncoder(w).Encode(newRootDroplet(droplet))

			}

			err = withClient(http.HandlerFunc(handler), func(client *godo.Client) error {
				m, ok := machine.(*Machine)
				if !ok {
					return fmt.Errorf("can't type assert %T to *Machine", machine)
				}

				m.client = client

				ctx := context.Background()
				state, _, _ := m.Info(ctx)
				if state != test.state {
					return fmt.Errorf("expecting %q, got: %q", test.state, state)
				}

				return nil
			})
			if err != nil {
				t.Fatal(err)
			}
		})
	}
}

func withClient(handler http.Handler, fn func(client *godo.Client) error) error {
	server := httptest.NewServer(handler)
	defer server.Close()

	client := godo.NewClient(nil)
	url, _ := url.Parse(server.URL)
	client.BaseURL = url

	return fn(client)
}

func newDoBaseMachine(dropletID int) *provider.BaseMachine {
	return &provider.BaseMachine{
		Machine:    &models.Machine{},
		Session:    nil,
		Credential: Provider.Schema.NewCredential(),
		Bootstrap:  Provider.Schema.NewBootstrap(),
		Metadata: Provider.Schema.NewMetadata(&stack.Machine{
			Attributes: map[string]string{"id": strconv.Itoa(dropletID)},
		}),
		Provider: "digitalocean",
	}
}

type rootAction struct {
	Action *godo.Action `json:"action"`
}

func newRootAction(action *godo.Action) *rootAction {
	return &rootAction{Action: action}
}

type rootDroplet struct {
	Droplet *godo.Droplet `json:"droplet"`
}

func newRootDroplet(droplet *godo.Droplet) *rootDroplet {
	return &rootDroplet{Droplet: droplet}
}
