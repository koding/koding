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
	var (
		needNewline bool
		err         error
	)

	for i := uint(0); i <= r.RetryOptions.StatusRetries; i++ {
		err = r.status()
		if err == nil {
			break
		}

		switch i {
		case 0:
			needNewline = true
			fmt.Fprint(r.Stdout, "Kontrol not connected. Waiting for reconnect.")
		default:
			fmt.Fprint(r.Stdout, " .")
		}

		time.Sleep(r.RetryOptions.StatusDelay)
	}

	if needNewline {
		fmt.Fprint(r.Stdout, "\n")
	}

	return err
}

func (r *KontrolRepair) status() error {
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
	if err := r.status(); err != nil {
		fmt.Fprintln(r.Stdout, "Unable to reconnect to kontrol.")
	}

	return nil
}
