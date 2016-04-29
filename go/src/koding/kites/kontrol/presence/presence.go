// Package presence provides stateful registration to Kontrol by queueing
// peers. Additionaly a single peer upon registration has a view of all already
// registrated peers, which can be used to e.g. implement unique registerURLs.
//
// This package is used by tunnelproxy/server to implement short urls
// per instance (a.koding.me, b.koding.me etc.).
package presence

import (
	"net"
	"net/url"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
	"github.com/koding/logging"
)

// Options
type Options struct {
	// Peers
	Peers *protocol.KontrolQuery

	// KiteConfig
	KiteConfig *config.Config

	// Log
	Log logging.Logger

	// PeerReady
	PeerReady func(*kite.Client) bool

	// PeerReadyTimeout
	PeerReadyTimeout time.Duration

	// RegFunc
	RegisterURL func(peers []*kite.Client) (*url.URL, error)

	// Debug
	Debug bool
}

// Client
type Client struct {
	*Options
}

// New
func NewClient(opts *Options) *Client {
	return &Client{
		Options: opts,
	}
}

// Register
func (c *Client) Register(name, version string) (*kite.Kite, *url.URL, error) {
	k := c.newKite(name, version)
	initialURL := k.RegisterURL(false)

	if err := k.RegisterForever(initialURL); err != nil {
		return nil, nil, err
	}

	ready, waitgroup, err := c.peers(k, initialURL)
	if err == kite.ErrNoKitesAvailable {
		return c.finalRegister(k, nil, name, version)
	}
	if err != nil {
		return nil, nil, err
	}

	if len(waitgroup) == 0 {
		return c.finalRegister(k, ready, name, version)
	}

	timeout := time.After(c.PeerReadyTimeout)
	var notready map[string]*kite.Client

	// We wait for kites that we initially observed as not ready.
	// Any other kite that joins the quorum later that we did,
	// we just ignore, since it is expected to wait for us
	// before it can proceed.

WaitForGroup:
	for len(waitgroup) != 0 {
		select {
		case <-timeout:
			break WaitForGroup
		default:
			time.Sleep(c.PeerReadyTimeout / 10)

			ready, notready, err = c.peers(k, initialURL)
			if err == kite.ErrNoKitesAvailable {
				return c.finalRegister(k, nil, name, version)
			}
			if err != nil {
				return nil, nil, err
			}

			for id := range waitgroup {
				if _, ok := notready[id]; !ok {
					delete(waitgroup, id)
				}
			}
		}
	}

	if len(waitgroup) != 0 {
		// This can happend, when a kite registered to Kontrol with initialURL,
		// but never managed to complete the final registration (e.g. crashed).
		ids := make([]string, 0, len(waitgroup))
		for id := range waitgroup {
			ids = append(ids, id)
		}

		c.Log.Warning("exceeded max allowed time waiting for the following kites to become ready: %v", ids)
	}

	return c.finalRegister(k, ready, name, version)
}

func (c *Client) peers(k *kite.Kite, self *url.URL) (ready, notready map[string]*kite.Client, err error) {
	kites, err := k.GetKites(c.Peers)
	if err != nil {
		return nil, nil, err
	}

	peers := make([]*kite.Client, 0, len(kites))
	selfHost := trimPort(self.Host)

	// filter out self by filtering out kites with public IP
	// the same as ours
	for _, k := range kites {
		u, err := url.Parse(k.URL)
		if err != nil {
			c.Log.Warning("%s: ignoring invalid kite with URL=%q: %s", k, k.URL, err)
			continue
		}

		if trimPort(u.Host) == selfHost {
			continue
		}

		peers = append(peers, k)
	}

	if len(peers) == 0 {
		return nil, nil, kite.ErrNoKitesAvailable
	}

	readyPerHost := make(map[string]*kite.Client)

	for _, k := range peers {
		if c.PeerReady(k) {
			readyPerHost[k.Kite.Hostname] = k
		}
	}

	notready = make(map[string]*kite.Client)

	// each kite registers twice - once with public IP, then again
	// with url built with c.RegisterURL; since Kontrol caches kites,
	// both of them are going to be listed in GetKites response;
	// the assumption here is if at least one kite from kites that
	// share the same hostname is ready, then those not-ready ones
	// are old, cached entries we we're going to ignore
	for _, k := range peers {
		if _, ok := readyPerHost[k.Kite.Hostname]; !ok {
			notready[k.String()] = k
		}
	}

	ready = make(map[string]*kite.Client, len(readyPerHost))

	for _, k := range readyPerHost {
		ready[k.String()] = k
	}

	return ready, notready, nil
}

func (c *Client) finalRegister(k *kite.Kite, ready map[string]*kite.Client, name, version string) (*kite.Kite, *url.URL, error) {
	peers := make([]*kite.Client, 0, len(ready))
	for _, k := range ready {
		peers = append(peers, k)
	}

	registerURL, err := c.RegisterURL(peers)

	k.Close()

	if err != nil {
		return nil, nil, err
	}

	k = c.newKite(name, version)

	if err = k.RegisterForever(registerURL); err != nil {
		return nil, nil, err
	}

	return k, registerURL, nil
}

func (c *Client) newKite(name, version string) *kite.Kite {
	k := kite.New(name, version)
	k.Log = c.Log
	k.Config = c.KiteConfig

	if c.Debug {
		k.SetLogLevel(kite.DEBUG)
	}

	return k
}

func trimPort(s string) string {
	host, _, err := net.SplitHostPort(s)
	if err != nil {
		return s
	}

	return host
}
