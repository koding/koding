package repair

import (
	"errors"
	"fmt"
	"io"
	"koding/klient/remote/req"
	"time"
)

// RemoteMachineRepair (name TBA) checks the remote machine's kite connection,
// and waits for it to be healthy. If we cannot recover, it remounts.
type RemoteMachineRepair struct {
	// The name of the machine that the remote kite is using.
	MachineName string

	// The klient we will be communicating with.
	Klient interface {
		RemoteStatus(req.Status) (bool, error)
	}

	// The options that this repairer will use.
	RetryOptions RetryOptions

	// The way
	Stdout io.Writer
}

func (r *RemoteMachineRepair) String() string {
	return "remotekiterepair"
}

func (r *RemoteMachineRepair) Status() (bool, error) {
	var (
		newline bool
		ok      bool
		err     error
	)

	for i := uint(0); i <= r.RetryOptions.StatusRetries; i++ {
		ok, err = r.status()
		if ok {
			break
		}

		switch i {
		case 0:
			newline = true
			fmt.Fprintf(
				r.Stdout, "%s is not connected. Waiting for reconnect.", r.MachineName,
			)
		default:
			fmt.Fprint(r.Stdout, " .")
		}

		time.Sleep(r.RetryOptions.StatusDelay)
	}

	if newline {
		fmt.Fprint(r.Stdout, "\n")
	}

	return ok, err
}

func (r *RemoteMachineRepair) status() (bool, error) {
	return r.Klient.RemoteStatus(req.Status{
		Item: req.MachineStatus,
	})
}

func (r *RemoteMachineRepair) Repair() error {
	//_, err := r.Klient.RemoteMountInfo(req.Status{
	//	Item: req.MachineStatus,
	//})
	//return err
	return errors.New("Not implemented")
}
