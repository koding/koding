package tunnel

import (
	"errors"
	"fmt"
	"net"
	"strings"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/boltdb/bolt"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/tunnel"
	"github.com/koding/klient/protocol"
)

const (
	// dbBucket is the bucket name used to retrieve and store the resolved
	// address
	dbBucket = "klienttunnel"

	// dbKey is the key value to retrieve the value from the bucket
	dbKey = "resolved_addr"
)

var ErrKeyNotFound = errors.New("key not found")

type registerResult struct {
	VirtualHost string
	Identifier  string
}

type TunnelClient struct {
	db *bolt.DB
}

func NewClient(db *bolt.DB) *TunnelClient {
	return &TunnelClient{
		db: db,
	}
}

func (t *TunnelClient) Start(k *kite.Kite, conf *tunnel.ClientConfig) error {
	tunnelkite := kite.New("tunnelclient", "0.0.1")
	tunnelkite.Config = k.Config.Copy()
	if conf.Debug {
		tunnelkite.SetLogLevel(kite.DEBUG)
	}

	// Nothing is passed via command line flag, fallback to default values
	if conf.ServerAddr == "" {
		// first try to get a resolved addr from local config storage
		resolvedAddr, err := t.addressFromConfig()
		if err != nil {
			k.Log.Warning("couldn't retrieve resolved address from config: '%s'", err)

			switch protocol.Environment {
			case "development":
				conf.ServerAddr = "devtunnelproxy.koding.com"
			case "production":
				conf.ServerAddr = "tunnelproxy.koding.com"
			default:
				return fmt.Errorf("Tunnel server address is empty. No env found: %s",
					protocol.Environment)
			}
		} else {
			k.Log.Debug("Resolved address is retrieved from the config '%s'", resolvedAddr)
			conf.ServerAddr = resolvedAddr
		}
	}

	// Check if the addr is valid IP, the user might pass to us a valid IP.  If
	// it's not valid, we're going to resolve it first.
	if net.ParseIP(conf.ServerAddr) == nil {
		k.Log.Debug("Resolving '%s'", conf.ServerAddr)
		resolved, err := resolvedAddr(conf.ServerAddr)
		if err != nil {
			// just log if we couldn't resolve it
			k.Log.Warning("couldn't resolve '%s: %s", conf.ServerAddr, err)
		} else {
			k.Log.Debug("Address resolved to '%s'", resolved)
			conf.ServerAddr = resolved
		}
	}

	if err := t.saveToConfig(conf.ServerAddr); err != nil {
		k.Log.Warning("coulnd't save resolved addres to config: '%s'", err)
	}

	// append port if absent
	conf.ServerAddr = addPort(conf.ServerAddr, "80")

	k.Log.Debug("Connecting to tunnel server IP: '%s'", conf.ServerAddr)
	tunnelserver := tunnelkite.NewClient("http://" + conf.ServerAddr + "/kite")
	// Enable it later if needed
	// tunnelserver.LocalKite.Config.Transport = config.XHRPolling

	connected, err := tunnelserver.DialForever()
	if err != nil {
		return err
	}

	<-connected

	conf.FetchIdentifier = func() (string, error) {
		result, err := callRegister(tunnelserver)
		if err != nil {
			return "", err
		}

		k.Log.Info("Our tunnel public host is: '%s'", result.VirtualHost)
		return result.Identifier, nil
	}

	client, err := tunnel.NewClient(conf)
	if err != nil {
		return err
	}

	go client.Start()
	return nil
}

// addressFromConfig reads the resolvedAddress from the config.
func (t *TunnelClient) addressFromConfig() (string, error) {
	if t.db == nil {
		return "", errors.New("klienttunnel: boltDB reference is nil (addressFromConfig)")
	}

	// don't forget to create the bucket for the first time
	if err := t.db.Update(func(tx *bolt.Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte(dbBucket))
		if err != nil {
			return err
		}
		return nil
	}); err != nil {
		return "", err
	}

	var res string
	if err := t.db.View(func(tx *bolt.Tx) error {
		// retrieve bucket first
		bucket := tx.Bucket([]byte(dbBucket))

		// retrieve val, it might be non existent (possible for the first
		// retrieve). We don't return an error because it might be non nil but
		// still an empty valu. That's why we check it below for emptiness
		res = string(bucket.Get([]byte(dbKey)))
		return nil
	}); err != nil {
		return "", err
	}

	if res == "" {
		return "", ErrKeyNotFound
	}

	return res, nil
}

// saveToConfig saves the given resolved address to the locally stored configuration
func (t *TunnelClient) saveToConfig(resolvedAddr string) error {
	if resolvedAddr == "" {
		return errors.New("klienttunnel: can't save to config, resolved address is empty")
	}

	if t.db == nil {
		return errors.New("klienttunnel: boltDB reference is nil (saveToConfig)")
	}

	return t.db.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(dbBucket))
		return b.Put([]byte(dbKey), []byte(resolvedAddr))
	})
}

func callRegister(tunnelserver *kite.Client) (*registerResult, error) {
	response, err := tunnelserver.Tell("register", nil)
	if err != nil {
		return nil, err
	}

	result := &registerResult{}
	err = response.Unmarshal(result)
	if err != nil {
		return nil, err
	}

	return result, nil
}

func resolvedAddr(host string) (string, error) {
	addr, err := net.LookupHost(host)
	if err != nil {
		return "", err
	}

	if len(addr) == 0 {
		return "", fmt.Errorf("no resolved addresses found for '%s'", host)
	}

	return addr[0], nil
}

// hasPort detecths if the given name has a port or not
func hasPort(s string) bool { return strings.LastIndex(s, ":") > strings.LastIndex(s, "]") }

// addPort adds the port and returns "host:port". If the host already contains
// a port, it returns it.
func addPort(host, port string) string {
	if ok := hasPort(host); ok {
		return host
	}

	return host + ":" + port
}
