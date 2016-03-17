package repair

import (
	"fmt"
	"koding/klientctl/klient"
	"koding/klientctl/util"
)

// KlientRunningRepair looks for an actively running klient, and attempts
// connecting to it.
type KlientRunningRepair struct {
	Stdout *util.Fprint

	KlientOptions klient.KlientOptions

	// A struct that provides functionality for starting and stopping klient
	KlientService interface {
		IsKlientRunning() bool
	}

	// A struct that runs the given command.
	Exec interface {
		Run(string, ...string) error
	}
}

func (r *KlientRunningRepair) String() string {
	return "klientrunningrepair"
}

// Status checks if the klient is running via the Klient Service, as well as
// dialing the klient to ensure that is working..
func (r *KlientRunningRepair) Status() (bool, error) {
	if !r.KlientService.IsKlientRunning() {
		r.Stdout.Printlnf("KD Daemon is not running.")
		return false, nil
	}

	if _, err := klient.NewDialedKlient(r.KlientOptions); err != nil {
		r.Stdout.Printlnf("Unable to connect to KD Daemon.")
		return false, nil
	}

	return true, nil
}

// Repair uses a subprocess of KD with Sudo, to enable the required Service
// permission. `kd repair` itself should not be called with sudo due to mounting/etc,
// and this is why a subprocess is being used.
func (r *KlientRunningRepair) Repair() error {
	r.Stdout.Printlnf("Attempting to restart KD Daemon. Your sudo password may be required..")

	if err := r.Exec.Run("sudo", "kd", "restart"); err != nil {
		return fmt.Errorf(
			"Subprocess kd failed to start. err:%s", err,
		)
	}

	// Run status again, to confirm it's running as best we can.
	ok, err := r.Status()

	// If there's an error checking Status, we have no idea what's wrong. The UX
	// may be vague, but there's nothing we can do.
	if err != nil {
		r.Stdout.Printlnf("Unable to determine status of KD Daemon.")
		return fmt.Errorf("Status returned error after Klient restart. err:%s", err)
	}

	// If Klient is not okay, inform the user that even after a successful restart,
	// it is not working properly.
	if !ok {
		r.Stdout.Printlnf("KD Daemon is not running properly.")
		return fmt.Errorf("Status returned not-okay, after Klient restart.")
	}

	return nil
}
