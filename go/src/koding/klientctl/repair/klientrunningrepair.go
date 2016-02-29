package repair

import (
	"errors"
	"fmt"
	"koding/klientctl/klient"
)

// KlientRunningRepair looks for an actively running klient, and attempts
// connecting to it.
type KlientRunningRepair struct {
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
func (r *KlientRunningRepair) Status() error {
	if !r.KlientService.IsKlientRunning() {
		return errors.New("Klient is not running")
	}

	if _, err := klient.NewDialedKlient(r.KlientOptions); err != nil {
		return fmt.Errorf("Unable to dial klient. err:%s", err)
	}

	return nil
}

// Repair uses a subprocess of KD with Sudo, to enable the required Service
// permission. `kd repair` itself should not be called with sudo due to mounting/etc,
// and this is why a subprocess is being used.
func (r *KlientRunningRepair) Repair() error {
	if err := r.Exec.Run("sudo", "kd", "restart"); err != nil {
		return fmt.Errorf(
			"Subprocess kd failed to start. err:%s", err,
		)
	}

	// Run status again, to confirm it's running as best we can.
	return r.Status()
}
