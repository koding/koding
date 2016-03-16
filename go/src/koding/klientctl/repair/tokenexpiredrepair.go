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

// TokenExpiredRepair checks if our kite client is using an expired token.
// For further detail see the Status and Repair methods respectively.
type TokenExpiredRepair struct {
	Log logging.Logger

	// The name of the machine that the remote kite is using.
	MachineName string

	// The klient we will be communicating with.
	Klient interface {
		RemoteStatus(req.Status) error
	}

	// How long Repair will wait for the token to not be expired, because restarting
	// klient is not always the best solution.
	RepairWaitForToken time.Duration

	// The way
	Stdout io.Writer

	// A struct that runs the given command. Used to restart klient.
	Exec interface {
		Run(string, ...string) error
	}
}

func (r *TokenExpiredRepair) String() string {
	return "TokenExpiredRepair"
}

// Status simply checks if the remote kite's status is TokenExpired.
func (r *TokenExpiredRepair) Status() (bool, error) {
	request := req.Status{
		Item:        req.MachineStatus,
		MachineName: r.MachineName,
	}

	if err := r.Klient.RemoteStatus(request); err != nil {
		// If the error is not what this repairer is designed to handle, return ok.
		// This seems counter intuitive, but if this Status() returns false, it is
		// expected to fix the error. We don't know what that error is, so we shouldn't
		// report a bad status. Log it, for debugging purposes though, and hope the
		// next repairer in the list knows how to deal with this issue.
		kErr, ok := err.(*kite.Error)
		if !ok || kErr.Type != kiteerrortypes.AuthErrTokenIsExpired {
			r.Log.Warning("Encountered error not in scope of this repair. err:%s", err)
			return true, nil
		}

		return false, nil
	}

	return true, nil
}

// Repair if the token is expired, we can repair it (usually) by restarting klient.
// Expired tokens will eventually be renewed, so we do try and wait some time.
//
// number of retries. In the end, this Repair behaves similar to internet repair.
func (r *TokenExpiredRepair) Repair() error {
	fmt.Fprint(r.Stdout, "Auth token is expired, waiting for it renew.")

	start := time.Now()
	for time.Now().Sub(start) < r.RepairWaitForToken {
		// Ignoring the error here, because we want to wait no matter what.
		if ok, _ := r.Status(); ok {
			// Close the dot progress
			fmt.Fprint(r.Stdout, "\n")
			return nil
		}

		// Show a dot progress
		fmt.Fprint(r.Stdout, ".")

		time.Sleep(1 * time.Second)
	}

	// Close the dot progress
	fmt.Fprint(r.Stdout, "\n")

	// If the token is still expired after r.RepairWaitForToken duration, our only
	// choice is to restart klient and hope the token gets fixed.
	if err := r.Exec.Run("sudo", "kd", "restart"); err != nil {
		fmt.Fprintln(r.Stdout,
			"Error: Restarting KD failed. Please wait a moment and try again",
		)
		// The err here is likely just the exit status, but it's all we got.
		return fmt.Errorf(
			"Subprocess kd failed to restart klient. err:%s", err,
		)
	}

	ok, err := r.Status()
	if !ok || err != nil {
		fmt.Fprintln(r.Stdout,
			"Error: Unable to renew auth token. Please wait a moment and try again..",
		)

		// If the error is nil, make an error to return
		if err == nil {
			err = errors.New("Unable to wait for the token to become not expired.")
		}

		return err
	}

	return nil
}
