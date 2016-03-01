package repair

import (
	"fmt"
	"io"
	"koding/klient/remote/req"
	"time"

	"github.com/koding/logging"
)

type KontrolRepair struct {
	Log logging.Logger

	// The klient we will be communicating with.
	Klient interface {
		RemoteStatus(req.Status) error
	}

	// The options that this repairer will use.
	RetryOptions RetryOptions

	// The way
	Stdout io.Writer

	// A struct that runs the given command.
	Exec interface {
		Run(string, ...string) error
	}
}

func (r *KontrolRepair) String() string {
	return "kontrolrepair"
}

func (r *KontrolRepair) Status() error {
	if err := r.remoteStatus(); err == nil {
		return nil
	}

	fmt.Fprint(r.Stdout, "Kontrol not connected. Waiting for reconnect.")

	return r.statusLoop()
}

// statusLoop runs the status loop, optionally printing a dot to indicate progress.
func (r *KontrolRepair) statusLoop() error {
	var err error

	for i := uint(0); i <= r.RetryOptions.StatusRetries; i++ {
		if err = r.remoteStatus(); err == nil {
			break
		}

		fmt.Fprint(r.Stdout, ".")

		time.Sleep(r.RetryOptions.StatusDelay)
	}

	return err
}

func (r *KontrolRepair) remoteStatus() error {
	return r.Klient.RemoteStatus(req.Status{
		Item: req.KontrolStatus,
	})
}

func (r *KontrolRepair) Repair() error {
	fmt.Fprintln(r.Stdout, "Kontrol has not reconnected in expected time. Restarting.")

	if err := r.Exec.Run("sudo", "kd", "restart"); err != nil {
		return fmt.Errorf(
			"Subprocess kd failed to start. err:%s", err,
		)
	}

	// Run status again, to confirm it's running as best we can. If not, we've
	// tried and failed.
	fmt.Fprint(r.Stdout, "Waiting for reconnect.")

	if err := r.statusLoop(); err != nil {
		fmt.Fprintln(r.Stdout, "Unable to reconnect to kontrol.")
		return err
	}

	fmt.Fprint(r.Stdout, "\nReconnected to kontrol.")
	return nil
}
