package main

import (
	"errors"
	"fmt"
	"os"
	"syscall"

	"github.com/inconshreveable/go-update"
	"github.com/koding/kite"
	"github.com/mitchellh/osext"
)

var (
	AuthenticatedUser = "koding"
)

type UpdateData struct {
	KlientURL string
}

func updater(r *kite.Request) (interface{}, error) {
	if r.Username != AuthenticatedUser {
		return nil, fmt.Errorf("Not authenticated to make an update: %s", r.Username)
	}

	var params UpdateData
	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if params.KlientURL == "" {
		return nil, errors.New("Can't update myself, incoming URL is empty")
	}

	// can't return the result during update
	go func() {
		if err := updateBinary(params.KlientURL); err != nil {
			r.LocalKite.Log.Warning("Update fail: %v", err)
		}
	}()

	return true, nil
}

func updateBinary(url string) error {
	u := update.New()
	err := u.CanUpdate()
	if err != nil {
		return err
	}

	self, err := osext.Executable()
	if err != nil {
		return err
	}

	err, errRecover := u.FromUrl(url)
	if err != nil {
		if errRecover != nil {
			return errRecover
		}

		return err
	}

	env := os.Environ()

	execErr := syscall.Exec(self, []string{self}, env)
	if execErr != nil {
		return err
	}

	return nil
}
