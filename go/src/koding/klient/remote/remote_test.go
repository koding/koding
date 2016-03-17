package remote

import (
	"errors"
	"io/ioutil"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"

	"koding/klient/remote/machine"
	"koding/klient/storage"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
	"github.com/koding/logging"
)

var discardLogger logging.Logger

func init() {
	discardLogger = logging.NewLogger("testLogger")
	discardLogger.SetHandler(logging.NewWriterHandler(ioutil.Discard))
}

func newMockKiteGetter() *mockKiteGetter {
	return &mockKiteGetter{}
}

type mockKiteGetter struct {
	// An error to return on GetKites, if any
	GetKitesError error

	Clients []*KodingClient
}

// /kodingteam/managed/klient/0.1.200/public-region/walterwhite.local/174ef131-0af2-4943-58cf-cfd48d71fe49
func (m *mockKiteGetter) AddByUrl(s ...string) {
	for _, u := range s {
		m.Clients = append(m.Clients, &KodingClient{Client: &kite.Client{URL: u}})
	}
}

func (m *mockKiteGetter) GetKodingKites(_ *protocol.KontrolQuery) ([]*KodingClient, error) {
	if m.GetKitesError != nil {
		return nil, m.GetKitesError
	}

	return m.Clients, nil
}

func TestGetMachines(t *testing.T) {
	kg := newMockKiteGetter()
	kg.AddByUrl("http://testhost1:56789")

	store := storage.NewMemoryStorage()
	r := &Remote{
		localKite: &kite.Kite{
			Id: "test id",
			Config: &config.Config{
				Username: "test user",
			},
		},
		kitesGetter:       kg,
		log:               discardLogger,
		machinesCacheMax:  1 * time.Second,
		machineNamesCache: map[string]string{},
		machines:          machine.NewMachines(discardLogger, store),
		storage:           store,
	}

	machines, err := r.GetMachines()
	if err != nil {
		t.Error(err)
	}

	// Should return all kites
	if machines.Count() != 1 {
		t.Fatalf(
			"Expected GetKites to return all current kites. Wanted %d, got %d",
			1, machines.Count(),
		)
	}

	kg.AddByUrl("http://testhost2:56789")

	machines, err = r.GetMachines()
	if err != nil {
		t.Error(err)
	}

	// Should return only the cached kites
	if machines.Count() != 1 {
		t.Errorf(
			"Expected GetKites to cache results. Expected %d, got %d",
			1, machines.Count(),
		)
	}

	// Wait longer than the kite timeout
	time.Sleep(2 * time.Second)

	machines, err = r.GetMachines()
	if err != nil {
		t.Error(err)
	}

	// Should not use the cache
	if machines.Count() != 2 {
		t.Errorf(
			"Expected GetKites clear cache. Expected %d results, got %d",
			2, machines.Count(),
		)
	}

	// Tell the kite getter to fail
	kg.GetKitesError = errors.New("KitesGetter test error")
	kg.AddByUrl("http://testhost3:56789")

	machines, err = r.GetMachines()

	// Should return the old results if the KitesGetter returns an error
	if machines.Count() != 2 {
		t.Errorf(
			"Expected GetKites return the cache when KitesGetter fails, within the clientsErrCacheMax duration. Expected %d results, got %d",
			2, machines.Count(),
		)
	}

	// Should not return an error when returning a cache
	if err != nil {
		t.Errorf("Expected GetKites to not return an error if it is returning a cache. Expected nil, got '%s'", err.Error())
	}

	// Sleep past the clientsErrCacheMax duration
	time.Sleep(3 * time.Second)

	machines, err = r.GetMachines()

	// Should return the error when the clientsErrCacheMax is too old
	if err == nil {
		t.Error("Expected GetKites to return an error when after clientsErrCacheMax. Got nil.")
	}

	// Should not return any results after the clientsErrCacheMax
	// duration
	if machines != nil {
		t.Errorf(
			"Expected GetMachines not to return the machines cache when KitesGetter failes after clientsErrCacheMax. Expected nil machine",
		)
	}
}

func TestGetMachinesWithoutCache(t *testing.T) {
	Convey("Given a new machine", t, func() {
		kg := newMockKiteGetter()
		kg.AddByUrl("http://testhost1:56789")

		store := storage.NewMemoryStorage()
		r := &Remote{
			localKite: &kite.Kite{
				Id: "test id",
				Config: &config.Config{
					Username: "test user",
				},
			},
			kitesGetter:       kg,
			log:               discardLogger,
			machines:          machine.NewMachines(discardLogger, store),
			machinesCacheMax:  1 * time.Second,
			machineNamesCache: map[string]string{},
			storage:           store,
		}

		// Sanity check our config
		So(kg.Clients[0].Reconnect, ShouldBeFalse)
		Convey("It should configure the kite Client", func() {
			r.GetMachinesWithoutCache()
			So(kg.Clients[0].Reconnect, ShouldBeTrue)
		})
	})

	Convey("Given a pre existing machine", t, func() {
		kg := newMockKiteGetter()
		kg.AddByUrl("http://testhost1:56789")

		store := storage.NewMemoryStorage()
		r := &Remote{
			localKite: &kite.Kite{
				Id: "test id",
				Config: &config.Config{
					Username: "test user",
				},
			},
			kitesGetter: kg,
			log:         discardLogger,
			machines:    machine.NewMachines(discardLogger, store),
			storage:     store,
		}

		// Add a machine, with just enough info to serve our needs
		r.machines.Add(&machine.Machine{
			MachineMeta: machine.MachineMeta{
				IP: "localhost1",
			},
		})

		// Sanity check our config
		So(kg.Clients[0].Reconnect, ShouldBeFalse)
		Convey("It should configure the kite Client", func() {
			r.GetMachinesWithoutCache()
			So(kg.Clients[0].Reconnect, ShouldBeTrue)
		})
	})
}
