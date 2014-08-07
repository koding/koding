package main

import (
	"bytes"
	"compress/gzip"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"syscall"
	"time"

	"github.com/inconshreveable/go-update"
	"github.com/koding/kite"
	"github.com/mitchellh/osext"
)

var (
	AuthenticatedUser = "koding"

	// EndpointURL returns the latest stable klient version
	EndpointUrl = ""
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

	bin, err := fetchBinGz(url)
	if err != nil {
		return err
	}

	err, errRecover := u.FromStream(bytes.NewBuffer(bin))
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

func fetchBinGz(url string) ([]byte, error) {
	r, err := fetch(url)
	if err != nil {
		return nil, err
	}
	defer r.Close()

	buf := new(bytes.Buffer)
	gz, err := gzip.NewReader(r)
	if err != nil {
		return nil, err
	}

	if _, err = io.Copy(buf, gz); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

func fetch(url string) (io.ReadCloser, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}

	switch resp.StatusCode {
	case 200:
		return resp.Body, nil
	default:
		return nil, fmt.Errorf("bad http status from %s: %v", url, resp.Status)
	}
}

func backgroundUpdater() {
	for _ = range time.Tick(time.Minute * 5) {
		// check from an endpoint
		if err := updateBinary(EndpointUrl); err != nil {
			klog.Warning("Self-update report: %s", err)
		}
	}
}
