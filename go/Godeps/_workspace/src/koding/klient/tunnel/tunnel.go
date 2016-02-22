// Package tunnel is responsible of setting up and connecting to a tunnel
// server.
package tunnel

import (
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strings"

	"koding/kites/tunnelproxy"
	"koding/klient/protocol"

	"github.com/boltdb/bolt"
)

const (
	// dbBucket is the bucket name used to retrieve and store the resolved
	// address
	dbBucket = "klienttunnel"

	// dbKey is the key value to retrieve the value from the bucket
	dbKey = "resolved_addr"
)

var ErrKeyNotFound = errors.New("key not found")

type TunnelClient struct {
	db     *bolt.DB
	client *tunnelproxy.Client
}

// NewClient returns a new tunnel client instance.
func NewClient(db *bolt.DB) *TunnelClient {
	return &TunnelClient{
		db: db,
	}
}

// Start setups the client and connects to a tunnel server based on the given
// configuration. It's non blocking and should be called only once.
func (t *TunnelClient) Start(opts *tunnelproxy.ClientOptions, vhost string) (string, error) {
	if err := t.updateOptions(opts); err != nil {
		return "", err
	}

	if vh, err := url.Parse(vhost); err == nil {
		opts.VirtualHost = vh.Host
	}

	opts.Log.Debug("Connecting to tunnel server IP: '%s'", opts.ServerAddr)

	client, err := tunnelproxy.NewClient(opts)
	if err != nil {
		return "", err
	}

	if err := client.Start(); err != nil {
		return "", err
	}

	t.client = client

	return t.client.VirtualHost, nil
}

func (t *TunnelClient) updateOptions(opts *tunnelproxy.ClientOptions) error {
	// our defaults
	var tunnelServerPort = "80"
	var tunnelHost = ""
	switch protocol.Environment {
	case "managed", "production":
		tunnelHost = "tunnelproxy.koding.com"
	case "development":
		tunnelHost = "devtunnelproxy.koding.com"
	}

	// Nothing is passed via command line flag, fallback to default values
	if opts.ServerAddr == "" {
		// first try to get a resolved addr from local config storage
		resolvedAddr, err := t.addressFromConfig()
		if err != nil {
			// show errors different than ErrKeyNotFound, because this will be
			// showed %100 of the times for every user.
			if err != ErrKeyNotFound {
				opts.Log.Warning("couldn't retrieve resolved address from config: '%s' ", err)
			}

			opts.ServerAddr = tunnelHost
		} else {
			opts.Log.Debug("Resolved address is retrieved from the config '%s'", resolvedAddr)

			opts.ServerAddr = resolvedAddr
			// be sure it's alive, if not we are going to use hostname, which
			// will resolved to a correct alive server
			if err := isAlive(resolvedAddr); err != nil {
				opts.ServerAddr = tunnelHost
				opts.Log.Warning("server is not healthy: %s", err)
			}
		}
	} else {
		// check if the user passed with a port and extract it
		host, port, err := net.SplitHostPort(opts.ServerAddr)
		if err != nil {
			return err // this is users fault, return an error
		}

		tunnelServerPort = port
		opts.ServerAddr = host
	}

	if opts.ServerAddr == "" {
		return errors.New("no tunnel server available for the given environment: " + protocol.Environment)
	}

	// Check if the addr is valid IP, the user might pass to us a valid IP.  If
	// it's not valid, we're going to resolve it first.
	if net.ParseIP(opts.ServerAddr) == nil {
		opts.Log.Debug("Resolving '%s'", opts.ServerAddr)
		resolved, err := resolvedAddr(opts.ServerAddr)
		if err != nil {
			// just log if we couldn't resolve it
			opts.Log.Warning("couldn't resolve '%s: %s", opts.ServerAddr, err)
		} else {
			opts.Log.Debug("Address resolved to '%s'", resolved)
			opts.ServerAddr = resolved
		}
	}

	opts.Log.Debug("Saving resolved address '%s' to config", opts.ServerAddr)
	if err := t.saveToConfig(opts.ServerAddr); err != nil {
		opts.Log.Warning("coulnd't save resolved addres to config: '%s'", err)
	}

	// append port if absent
	opts.ServerAddr = addPort(opts.ServerAddr, tunnelServerPort)
	return nil
}

// isAlive checks whether the given tunnel server addres is an healthy one.
func isAlive(addr string) error {
	resp, err := http.Get("http://" + addr + "/healthCheck")
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		return nil
	}

	return fmt.Errorf("Server '%s' respnds with status code '%d'", addr, resp.StatusCode)
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
		// still an empty value. That's why we check it below for emptiness
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

	return t.db.Update(func(tx *bolt.Tx) (err error) {
		b := tx.Bucket([]byte(dbBucket))
		if b == nil {
			b, err = tx.CreateBucketIfNotExists([]byte(dbBucket))
			if err != nil {
				return err
			}
		}
		return b.Put([]byte(dbKey), []byte(resolvedAddr))
	})
}

// resolvedAddr resolves the given host name to a IP and returns the first
// resolved address.
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

// hasPort detects if the given name has a port or not
func hasPort(s string) bool { return strings.LastIndex(s, ":") > strings.LastIndex(s, "]") }

// addPort adds the port and returns "host:port". If the host already contains
// a port, it returns it.
func addPort(host, port string) string {
	if ok := hasPort(host); ok {
		return host
	}

	return host + ":" + port
}
