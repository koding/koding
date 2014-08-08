package main

import (
	"bytes"
	"compress/gzip"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"syscall"
	"time"

	"github.com/hashicorp/go-version"
	"github.com/inconshreveable/go-update"
	"github.com/koding/kite"
	"github.com/mitchellh/osext"
)

var (
	AuthenticatedUser = "koding"

	// EndpointURL returns the latest stable klient version
	EndpointUrl = "https://s3.amazonaws.com/koding-kites/klient/latest.txt"
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

	klog.Info("Going to update binary at %s.", self)
	bin, err := fetchBinGz(url)
	if err != nil {
		return err
	}

	klog.Info("Everything is ready =====> UPDATING...")
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

func getLatestVersion() (string, error) {
	klog.Info("Getting latest version from %s", EndpointUrl)
	resp, err := http.Get(EndpointUrl)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	latest, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return strings.TrimSpace(string(latest)), nil
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
	klog.Info("Fetching binary %s", url)
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

func checkAndUpdate() error {
	l, err := getLatestVersion()
	if err != nil {
		return err
	}

	latestVer := "0.1." + l
	currentVer := VERSION

	klog.Info("Latest version is %s", latestVer)

	latest, err := version.NewVersion(latestVer)
	if err != nil {
		return err
	}

	current, err := version.NewVersion(currentVer)
	if err != nil {
		return err
	}

	klog.Info("Comparing current version %s with latest version %s", currentVer, latestVer)
	if !current.LessThan(latest) {
		return fmt.Errorf("Current version (%s) is equal or greater than latest (%s)", currentVer, latestVer)
	}

	klog.Info("Current version: %s is old. Going to update to: %s", currentVer, latestVer)

	basePath := "https://s3.amazonaws.com/koding-kites/klient/development/latest"
	latestKlientURL := basePath + "/klient-" + latestVer + ".gz"

	return updateBinary(latestKlientURL)
}

func backgroundUpdater() {
	for _ = range time.Tick(time.Second * 30) {
		if err := checkAndUpdate(); err != nil {
			klog.Warning("Self-update report: %s", err)
		}
	}
}
