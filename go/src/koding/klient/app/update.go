package app

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"sync"
	"syscall"
	"time"

	"koding/klient/protocol"

	"github.com/hashicorp/go-version"
	"github.com/inconshreveable/go-update"
	"github.com/koding/kite"
	"github.com/mitchellh/osext"
)

type Updater struct {
	Endpoint       string
	Interval       time.Duration
	CurrentVersion string
	Log            kite.Logger
	Wait           sync.WaitGroup
}

type UpdateData struct {
	KlientURL string
}

var AuthenticatedUser = "koding"

func (u *Updater) ServeKite(r *kite.Request) (interface{}, error) {
	if r.Username != AuthenticatedUser {
		return nil, fmt.Errorf("Not authenticated to make an update: %s", r.Username)
	}

	go func() {
		r.LocalKite.Log.Info("klient.Update is called. Updating binary via latest version")

		if err := u.checkAndUpdate(); err != nil {
			u.Log.Warning("klient.update: %s", err)
		}
	}()

	return true, nil
}

func (u *Updater) checkAndUpdate() error {
	if err := hasFreeSpace(100); err != nil {
		return err
	}

	l, err := u.latestVersion()
	if err != nil {
		return err
	}

	latestVer := "0.1." + l
	latest, err := version.NewVersion(latestVer)
	if err != nil {
		return err
	}

	current, err := version.NewVersion(u.CurrentVersion)
	if err != nil {
		return err
	}

	if !current.LessThan(latest) {
		// current running binary version is equal or greater than what we fetched, so return we don't need to update
		return nil
	}

	u.Log.Info("Current version: %s is old. Going to update to: %s", u.CurrentVersion, latestVer)

	basePath := "https://s3.amazonaws.com/koding-klient/" + protocol.Environment + "/latest"
	latestKlientURL := basePath + "/klient-" + latestVer + ".gz"

	return u.updateBinary(latestKlientURL)
}

func (u *Updater) updateBinary(url string) error {
	updater := update.New()
	err := updater.CanUpdate()
	if err != nil {
		return err
	}

	self, err := osext.Executable()
	if err != nil {
		return err
	}

	u.Log.Info("Going to update binary at: %s", self)
	bin, err := u.fetch(url)
	if err != nil {
		return err
	}

	u.Wait.Add(1)
	defer u.Wait.Done()

	u.Log.Info("Replacing new binary with the old one.")
	err, errRecover := updater.FromStream(bytes.NewBuffer(bin))
	if err != nil {
		if errRecover != nil {
			return errRecover
		}

		return err
	}

	env := os.Environ()

	// TODO: os.Args[1:] should come also from the endpoint if the new binary
	// has a different flag!
	args := []string{self}
	args = append(args, os.Args[1:]...)

	// we need to call it here now too, because syscall.Exec will prevent to
	// call the defer that we've defined in the beginning.

	u.Log.Info("Updating was successfull. Replacing current process with args: %v\n=====> RESTARTING...\n\n", args)

	execErr := syscall.Exec(self, args, env)
	if execErr != nil {
		return err
	}

	return nil
}

func (u *Updater) latestVersion() (string, error) {
	resp, err := http.Get(u.Endpoint)
	if err != nil {
		u.Log.Debug("Getting latest version from %s", u.Endpoint)
		return "", err
	}
	defer resp.Body.Close()

	latest, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return strings.TrimSpace(string(latest)), nil
}

func (u *Updater) fetch(url string) ([]byte, error) {
	u.Log.Info("Fetching binary %s", url)
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("bad http status from %s: %v", url, resp.Status)
	}

	buf := new(bytes.Buffer)
	gz, err := gzip.NewReader(resp.Body)
	if err != nil {
		return nil, err
	}
	defer gz.Close()

	if _, err = io.Copy(buf, gz); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

// Run runs the updater in the background for the interval of updater interval.
func (u *Updater) Run() {
	u.Log.Info("Starting Updater with following options:\n\tinterval of: %s\n\tendpoint: %s",
		u.Interval, u.Endpoint)

	for _ = range time.Tick(u.Interval) {
		if err := u.checkAndUpdate(); err != nil {
			u.Log.Warning("Self-update: %s", err)
		}
	}
}

// hasFreeSpace checks whether the disk has free space to provide the update.
// If free space is lower than then the given mustHave it returns an error.
func hasFreeSpace(mustHave uint64) error {
	stat := new(syscall.Statfs_t)

	if err := syscall.Statfs("/", stat); err != nil {
		return err
	}

	// free is in MB
	free := (uint64(stat.Bavail) * uint64(stat.Bsize)) / (1024 * 1024)

	if free < mustHave {
		return fmt.Errorf("No enough space to upgrade klient. Need '%d'. Have: '%d'",
			mustHave, free)
	}

	return nil
}
