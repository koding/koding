package main

import (
	"koding/klientctl/klient"
	"path/filepath"
)

// NewKlientOptions creates a new KlientOptions object with fields defined
// as the config package specifies.
//
// TODO: Move this to the klient package, once config is properly packaged. Not
// doing it here, just to keep commits small and sane.
func NewKlientOptions() klient.KlientOptions {
	return klient.KlientOptions{
		Address:     KlientAddress,
		KiteKeyPath: filepath.Join(KiteHome, "kite.key"),
		Name:        Name,
		Version:     KiteVersion,
	}
}
