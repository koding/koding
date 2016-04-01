package remount

import (
	"fmt"
	"koding/klientctl/klient"
)

type RemountCommand struct {
	MountName     string
	KlientOptions klient.KlientOptions
	Klient        interface {
		RemoteRemount(string) error
	}
}

func (r *RemountCommand) Run() error {
	// setup our klient, if needed
	if err := r.setupKlient(); err != nil {
		return err
	}

	return r.Klient.RemoteRemount(r.MountName)
}

func (r *RemountCommand) setupKlient() error {
	if r.Klient != nil {
		return nil
	}

	k, err := klient.NewDialedKlient(r.KlientOptions)
	if err != nil {
		return fmt.Errorf("Failed to get working Klient instance.")
	}

	r.Klient = k

	return nil
}
