package etcd

import (
	"errors"

	"github.com/coreos/go-etcd/etcd"
	"github.com/koding/kite/kontrol"
	"github.com/koding/kite/kontrol/node"
	"github.com/koding/kite/protocol"
)

var (
	DefaultDiscoveryURL = "http://discovery.koding.io"

	ErrNotFound = errors.New("no kontrol kites found")
)

// Kontrol defines a single Kontrol entity with URL stored in etcd cluster.
type Kontrol struct {
	Kite protocol.Kite
	URL  string
}

// GetKontrols returns a list of kontrol URLs from a set of etcd instances
// behind a load balancer.
func Kontrols(query *protocol.KontrolQuery) ([]*Kontrol, error) {
	client := etcd.NewClient([]string{DefaultDiscoveryURL})

	// Set the logger to see what's going on.
	// etcd.SetLogger(log.New(os.Stderr, "etcd-discovery ", log.LstdFlags))

	// STRONG_CONSISTENCY doesn't play good with AMAZON ELB
	client.SetConsistency(etcd.WEAK_CONSISTENCY)

	etcdKey, err := kontrol.GetQueryKey(query)
	if err != nil {
		return nil, err
	}

	resp, err := client.Get("/kites"+etcdKey, false, true)
	if err != nil {
		return nil, err
	}

	node := node.New(resp.Node)

	kites, err := node.Kites()
	if err != nil {
		return nil, err
	}

	if len(kites) == 0 {
		return nil, ErrNotFound
	}

	var kontrols []*Kontrol = make([]*Kontrol, len(kites))

	for i, kite := range kites {
		kontrols[i] = &Kontrol{
			Kite: kite.Kite,
			URL:  kite.URL,
		}
	}

	return kontrols, nil
}
