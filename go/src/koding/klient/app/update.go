package app

import (
	"bytes"
	"compress/gzip"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"runtime"
	"strconv"
	"sync"
	"syscall"
	"time"

	konfig "koding/klient/config"
	"koding/klient/remote/mount"

	"github.com/hashicorp/go-version"
	update "github.com/inconshreveable/go-update"
	"github.com/kardianos/osext"
	"github.com/koding/kite"
)

type Updater struct {
	Endpoint       string
	Interval       time.Duration
	CurrentVersion string
	KontrolURL     string
	Log            kite.Logger
	Wait           sync.WaitGroup
	MountEvents    <-chan *mount.Event
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

	l, err := u.latestVersion(konfig.Environment)
	if err != nil {
		return err
	}

	latest, err := version.NewVersion(fmt.Sprintf("0.1.%d", l))
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

	return u.update(latest, konfig.Environment)
}

func (u *Updater) update(latest *version.Version, env string) error {
	return u.updateBinary(u.endpointKlient(env, latest), latest)
}

// checkAndMigrate migrates from development environment
// to production.
//
// Prior to 210 version, kloud did use development klient
// on production. In order to migrate all them back to
// production channel, then env is overwritten here.
func (u *Updater) checkAndMigrate() error {
	if err := hasFreeSpace(100); err != nil {
		return err
	}

	if konfig.Environment != "development" || u.KontrolURL != "https://koding.com/kontrol/kite" {
		return nil
	}

	l, err := u.latestVersion("production")
	if err != nil {
		return err
	}

	latest, err := version.NewVersion(fmt.Sprintf("0.1.%d", l))
	if err != nil {
		return err
	}

	return u.update(latest, "production")
}

func (u *Updater) updateBinary(url string, latest *version.Version) error {
	u.Log.Info("Current version: %s is old. Going to update to: %s", u.CurrentVersion, latest)

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

	if err = update.Apply(bytes.NewBuffer(bin), update.Options{}); err != nil {
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

func (u *Updater) endpointVersion(env string) string {
	if u.Endpoint != "" {
		return u.Endpoint
	}

	return "https://koding-klient.s3.amazonaws.com/" + env + "/latest-version.txt"
}

func (u *Updater) endpointKlient(env string, latest *version.Version) string {
	var file string
	if runtime.GOOS != "linux" {
		// Backward-compatibility - linux uploads of klient are not suffixed
		// with a platform_arch string.
		//
		// TODO(rjeczalik): Remove when we ensure all klients in the wild
		// use new urls.
		file = fmt.Sprintf("klient-%s.%s_%s.gz", latest, runtime.GOOS, runtime.GOARCH)
	} else {
		file = fmt.Sprintf("klient-%s.gz", latest)
	}

	return fmt.Sprintf("https://koding-klient.s3.amazonaws.com/%s/%d/%s", env, latest.Segments()[2], file)
}

func (u *Updater) latestVersion(env string) (int, error) {
	resp, err := http.Get(u.endpointVersion(env))
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return 0, errors.New(http.StatusText(resp.StatusCode))
	}

	latest, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return 0, err
	}

	return strconv.Atoi(string(bytes.TrimSpace(latest)))
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
		u.Interval, u.endpointVersion(konfig.Environment))

	mounts := make(map[string]struct{})
	enabled := true
	ticker := time.NewTicker(u.Interval)

	for {
		select {
		case ev, ok := <-u.MountEvents:
			if !ok {
				return
			}

			// decide whether it's a new mount, failed mount or successful unmount
			switch ev.Type {
			case mount.EventMounting, mount.EventMounted:
				if ev.Err != nil {
					ok = false // failed mount
				} else {
					ok = true // successful mount or mount in progress
				}

			case mount.EventUnmounted:
				ok = false // successful unmount
			}

			// track or untracked mounted path
			if ok {
				mounts[ev.Path] = struct{}{}
			} else {
				delete(mounts, ev.Path)
			}

			// enable or disable autoupdate ticker
			if len(mounts) > 0 {
				u.Log.Debug("%d mounted dirs, disabling updater", len(mounts))

				enabled = false
			} else {
				u.Log.Debug("no mounted dirs, enabling updater")

				enabled = true
			}

		case <-ticker.C:
			if !enabled {
				continue
			}

			if err := u.checkAndMigrate(); err != nil {
				u.Log.Warning("self-migrate: %s", err)
			}

			if err := u.checkAndUpdate(); err != nil {
				u.Log.Warning("self-update: %s", err)
			}
		}
	}
}

// hasFreeSpace checks whether the disk has free space to provide the update.
// If free space is lower than then the given mustHave it returns an error.
func hasFreeSpace(mustHave uint64) error {
	stat := new(syscall.Statfs_t)

	// TODO(rjeczalik): /opt/kite/klient might be a separate filesystem,
	// so checking for / migtht not work.
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
