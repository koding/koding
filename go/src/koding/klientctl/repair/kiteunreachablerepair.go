package repair

import (
	"errors"
	"fmt"
	"io"
	"koding/klient/kiteerrortypes"
	"koding/klient/remote/req"
	"time"

	"github.com/koding/kite"
	"github.com/koding/logging"
)

// KiteUnreachableRepair checks if the remote kite is unreachable or not.
// For further detail see the Status and Repair methods respectively.
type KiteUnreachableRepair struct {
	Log logging.Logger

	// The name of the machine that the remote kite is using.
	MachineName string

	// The klient we will be communicating with.
	Klient interface {
		RemoteStatus(req.Status) error
	}

	// The retry options that this repairer will use.
	StatusRetries uint
	StatusDelay   time.Duration

	// The way
	Stdout io.Writer
}

func (r *KiteUnreachableRepair) String() string {
	return "KiteUnreachableRepair"
}

// Status simply checks if the remote kite's status is KiteUnreachable.
func (r *KiteUnreachableRepair) Status() (bool, error) {
	var (
		newline bool
		ok      bool
		err     error
	)

	for i := uint(0); i <= r.StatusRetries; i++ {
		err = r.Klient.RemoteStatus(req.Status{
			Item:        req.MachineStatus,
			MachineName: r.MachineName,
		})

		if err == nil {
			ok = true
			break
		}

		// If the error is not what this repairer is designed to handle, return ok.
		// This seems counter intuitive, but if this Status() returns false, it is
		// expected to fix the error. We don't know what that error is, so we shouldn't
		// report a bad status. Log it, for debugging purposes though, and hope the
		// next repairer in the list knows how to deal with this issue.
		//
		// TODO: Maybe we should retry here, instead of stopping? Ie, retry until
		// either:
		//   A. Everything is okay
		//   B. We encounter an error we can handle
		kErr, ok := err.(*kite.Error)
		if !ok || kErr.Type != kiteerrortypes.MachineUnreachable {
			r.Log.Warning("Encountered error not in scope of this repair. err:%s", err)
			break
		}

		switch i {
		case 0:
			newline = true
			fmt.Fprint(r.Stdout, "Machine is unreachable. Trying again.")
		default:
			fmt.Fprint(r.Stdout, ".")
		}

		time.Sleep(r.StatusDelay)
	}

	if newline {
		fmt.Fprint(r.Stdout, "\n")
	}

	return ok, err
}

// Repair cannot actually fix unreachable, Status should have been given a semi-high
// number of retries. In the end, this Repair behaves similar to internet repair.
func (r *KiteUnreachableRepair) Repair() error {
	fmt.Fprintln(r.Stdout,
		`Error: The remote machine does not appear to be running.
Please ensure it has port 56789 exposed and is turned on.`,
	)
	return errors.New("Machine not running")
}
