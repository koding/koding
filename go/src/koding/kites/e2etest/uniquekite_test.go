package e2etest

import (
	"errors"
	"fmt"
	"net"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"koding/kites/kontrol/presence"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
)

type UniqueKite struct {
	Hostname      string
	Delay         time.Duration
	RegisteredURL *url.URL
	Kite          *kite.Kite

	presence *presence.Client
	once     sync.Once
}

func (uk *UniqueKite) Register() error {
	uk.once.Do(uk.init)

	k, registerURL, err := uk.presence.Register()
	if err != nil {
		return err
	}

	uk.RegisteredURL = registerURL
	uk.Kite = k

	return nil
}

func (uk *UniqueKite) RegisteredName() string {
	if uk.RegisteredURL == nil {
		return ""
	}

	if strings.Count(uk.RegisteredURL.Host, ".") != 2 {
		return ""
	}

	return uk.RegisteredURL.Host[:strings.IndexRune(uk.RegisteredURL.Host, '.')]
}

func (uk *UniqueKite) PeerReady(k *kite.Client) bool {
	u, err := url.Parse(k.URL)
	if err != nil {
		panic(err)
	}

	return strings.Count(u.Host, ".") == 2
}

func (uk *UniqueKite) PeerHostname(k *kite.Client) string {
	u, err := url.Parse(k.URL)
	if err != nil {
		panic(err)
	}

	host := u.Host
	if h, _, err := net.SplitHostPort(host); err == nil {
		host = h
	}

	host = strings.TrimSuffix(host, ".localhost")

	if i := strings.LastIndex(host, "."); i != -1 {
		return host[i+1:]
	}

	return host
}

func (uk *UniqueKite) PeerReadyTimeout(n int) time.Duration {
	return time.Duration(n) * 90 * time.Second
}

func (uk *UniqueKite) RestoreURL(u *url.URL) error {
	time.Sleep(uk.delay()) // simulate long registration, e.g. DNS insertion
	return nil
}

func (uk *UniqueKite) RegisterURL(peers []*kite.Client) (*url.URL, error) {
	left := genUniqueNames(24)

	m, err := toUniqueNames(peers, left)
	if err != nil {
		return nil, err
	}

	for k := range m {
		delete(left, k)
	}

	time.Sleep(uk.delay()) // simulate long registration, e.g. DNS insertion

	if len(left) == 0 {
		return nil, errors.New("run out of unique names")
	}

	// Sort and pick always first available name to not
	// randomize urls in tests.
	names := make([]string, 0, len(left))
	for name := range left {
		names = append(names, name)
	}

	sort.Strings(names)

	Test.Log.Info("%s observed available names: %v, choosing %q\n", uk.Hostname, m, names[0])

	u := *uk.presence.InitialURL
	u.Host = names[0] + "." + u.Host

	return &u, nil
}

func (uk *UniqueKite) init() {
	cfg, _ := Test.GenKiteConfig()

	uk.presence = presence.NewClient(&presence.Options{
		Peers: &protocol.KontrolQuery{
			Name: "peerkite",
		},
		KiteConfig:  cfg,
		KiteName:    "peerkite",
		KiteVersion: "0.0.1",
		InitialURL: &url.URL{
			Scheme: "http",
			Host:   net.JoinHostPort(uk.Hostname+".localhost", strconv.Itoa(cfg.Port)),
			Path:   "/kite",
		},
		Log:              Test.Log,
		Debug:            true,
		KiteFunc:         kiteFunc,
		PeerReady:        uk.PeerReady,
		PeerHostname:     uk.PeerHostname,
		PeerReadyTimeout: uk.PeerReadyTimeout,
		RestoreURL:       uk.RestoreURL,
		RegisterURL:      uk.RegisterURL,
	})
}

func (uk *UniqueKite) delay() time.Duration {
	if uk.Delay != 0 {
		return uk.Delay
	}

	return 10 * time.Second
}

func kiteFunc(k *kite.Kite) {
	// overwrite kite's http.Client to understand *.localhost addresses
	// note: Chrome does understand "127.0.0.1 *.localhost", maybe stdlib should?
	k.ClientFunc = newClientFunc()
}

func genUniqueNames(n int) map[string]struct{} {
	m := make(map[string]struct{}, n)

	for ; n > 0; n-- {
		m[string('a'+n-1)] = struct{}{}
	}

	return m
}

func toUniqueNames(peers []*kite.Client, names map[string]struct{}) (map[string]struct{}, error) {
	m := make(map[string]struct{}, len(peers))

	for _, peer := range peers {
		u, err := url.Parse(peer.URL)
		if err != nil {
			return nil, err
		}

		name := u.Host
		if i := strings.IndexRune(name, '.'); i != -1 {
			name = name[:i]
		}

		if _, ok := names[name]; !ok {
			return nil, fmt.Errorf("invalid unique name: %s (%s)", name, peer.URL)
		}

		m[name] = struct{}{}
	}

	return m, nil
}
