package repair

import (
	"fmt"
	"io"
	"koding/klient/kiteerrortypes"
	"koding/klient/remote/req"
	"time"

	"github.com/koding/kite"
	"github.com/koding/logging"
)

// TokenNotYetValidRepair checks if the remote kite is experiencing token not
// yet valid.
// For further detail see the Status and Repair methods respectively.
type TokenNotYetValidRepair struct {
	Log logging.Logger

	// The name of the machine that the remote kite is using.
	MachineName string

	// The klient we will be communicating with.
	Klient interface {
		RemoteStatus(req.Status) error
	}

	// The retry options that this repairer will use.
	RepairRetries uint
	RepairDelay   time.Duration

	// The way
	Stdout io.Writer
}

func (r *TokenNotYetValidRepair) String() string {
	return "tokennotyetvalidrepair"
}

// Status simply checks if the remote kite's status is TokenNotYetValid.
func (r *TokenNotYetValidRepair) Status() error {
	err := r.Klient.RemoteStatus(req.Status{
		Item:        req.MachineStatus,
		MachineName: r.MachineName,
	})

	if err == nil {
		return nil
	}

	// If the error is not what this repairer is designed to handle, return ok.
	// This seems counter intuitive, but if this Status() returns false, it is
	// expected to fix the error. We don't know what that error is, so we shouldn't
	// report a bad status. Log it, for debugging purposes though, and hope the
	// next repairer in the list knows how to deal with this issue.
	kErr, ok := err.(*kite.Error)
	if !ok || kErr.Type != kiteerrortypes.AuthErrTokenIsNotValidYet {
		r.Log.Warning("Status encountered unhandled error err:%s", err)
		return nil
	}

	return err
}

// Repair is unable to actually fix this error, so we wait for a configured amount
// of time, checking if the status has *changed* since then.
//
// If another error is returned, we *do not return it* because we (in theory)
// allowed the token to become valid.
func (r *TokenNotYetValidRepair) Repair() error {
	var (
		newline bool
		err     error
	)

	for i := uint(0); i <= r.RepairRetries; i++ {
		if err = r.Status(); err == nil {
			break
		}

		// After our retry loop, print a newline.
		newline = true

		switch i {
		case 0:
			fmt.Fprintf(
				r.Stdout, "%s's auth token is not yet valid. Waiting for it to become valid.",
				r.MachineName,
			)
		default:
			fmt.Fprint(r.Stdout, ".")
		}

		time.Sleep(r.RepairDelay)
	}

	if newline {
		fmt.Fprint(r.Stdout, "\n")
	}

	fmt.Fprintln(r.Stdout, "Success, auth token now valid.")

	return err
}
