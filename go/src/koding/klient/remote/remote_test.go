package remote

import (
	"errors"
	"io/ioutil"
	"testing"
	"time"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite/config"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite/protocol"
	"github.com/koding/klient/storage"
	"github.com/koding/logging"
)

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

func TestGetKites(t *testing.T) {
	kg := newMockKiteGetter()
	kg.AddByUrl("http://testhost1:56789")

	logger := logging.NewLogger("testLogger")
	logger.SetHandler(logging.NewWriterHandler(ioutil.Discard))

	r := &Remote{
		localKite: &kite.Kite{
			Id: "test id",
			Config: &config.Config{
				Username: "test user",
			},
		},
		kitesGetter:       kg,
		log:               logger,
		machinesCacheMax:  1 * time.Second,
		machineNamesCache: map[string]string{},
		storage:           storage.NewMemoryStorage(),
	}

	machines, err := r.GetKites()
	if err != nil {
		t.Error(err)
	}

	// Should return all kites
	if len(machines) != 1 {
		t.Fatalf(
			"Expected GetKites to return all current kites. Wanted %d, got %d",
			1, len(machines),
		)
	}

	kg.AddByUrl("http://testhost2:56789")

	machines, err = r.GetKites()
	if err != nil {
		t.Error(err)
	}

	// Should return only the cached kites
	if len(machines) != 1 {
		t.Errorf(
			"Expected GetKites to cache results. Expected %d, got %d",
			1, len(machines),
		)
	}

	// Wait longer than the kite timeout
	time.Sleep(2 * time.Second)

	machines, err = r.GetKites()
	if err != nil {
		t.Error(err)
	}

	// Should clear cache
	if len(machines) != 2 {
		t.Errorf(
			"Expected GetKites clear cache. Expected %d results, got %d",
			2, len(machines),
		)
	}

	// Tell the kite getter to fail
	kg.GetKitesError = errors.New("KitesGetter test error")

	machines, err = r.GetKites()

	// Should return the old results if the KitesGetter returns an error
	if len(machines) != 2 {
		t.Errorf(
			"Expected GetKites return the cache when KitesGetter fails, within the clientsErrCacheMax duration. Expected %d results, got %d",
			2, len(machines),
		)
	}

	// Should not return an error when returning a cache
	if err != nil {
		t.Errorf("Expected GetKites to not return an error if it is returning a cache. Expected nil, got '%s'", err.Error())
	}

	kg.AddByUrl("http://testhost2:56789")

	// Sleep past the clientsErrCacheMax duration
	time.Sleep(3 * time.Second)

	machines, err = r.GetKites()

	// Should not return any results after the clientsErrCacheMax
	// duration
	if len(machines) != 0 {
		t.Errorf(
			"Expected GetKites not to return the kites cache when KitesGetter failes after clientsErrCacheMax. Expected %d results, got %d",
			0, len(machines),
		)
	}

	// Should return the error when the clientsErrCacheMax is too old
	if err == nil {
		t.Error("Expected GetKites to return an error when after clientsErrCacheMax. Got nil.")
	}
}
