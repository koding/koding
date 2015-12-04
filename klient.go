package main

import (
	"io/ioutil"
	"path/filepath"
	"strings"

	"github.com/koding/kite"
)

// NewKlientOptions creates a new KlientOptions object with fields defined
// as the config package specifies.
func NewKlientOptions() KlientOptions {
	return KlientOptions{
		Address:     KlientAddress,
		KiteKeyPath: filepath.Join(KiteHome, "kite.key"),
		Name:        Name,
		Version:     KiteVersion,
	}
}

// KlientOptions contains various fields for connecting to a klient.
type KlientOptions struct {
	// Address is the path to the Klient.
	Address string

	// KiteKeyPath is the full path to kite.key, which will be loaded and used
	// to authorize kdbin requests to Klient.
	KiteKeyPath string

	// Name, as passed to the first argument in `kite.New()`.
	Name string

	// Version, as passed to the second argument to `kite.New()`.
	Version string
}

// CreateKlientClient creates a kite to the klient specified by KlientOptions, and
// returns a Kite Client for that Klient.
func CreateKlientClient(opts KlientOptions) (*kite.Client, error) {
	k := kite.New("klientctl", opts.Version)
	c := k.NewClient(opts.Address)

	// If a key path is declared, load it and setup auth.
	if opts.KiteKeyPath != "" {
		data, err := ioutil.ReadFile(opts.KiteKeyPath)
		if err != nil {
			return nil, err
		}

		c.Auth = &kite.Auth{
			Type: "kiteKey",
			Key:  strings.TrimSpace(string(data)),
		}
	}

	return c, nil
}
