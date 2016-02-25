package repair

import (
	"errors"
	"koding/klientctl/klient"
)

// KlientRunningRepair looks for an actively running klient, and attempts
// connecting to it.
type KlientRunningRepair struct {
	KlientOptions klient.KlientOptions

	// A struct that provides functionality for starting and stopping klient
	KlientService interface {
		Start() error
		Stop() error
		IsKlientRunning() bool
	}
}

func (r *KlientRunningRepair) Name() string {
	return "klientrunningrepair"
}

func (r *KlientRunningRepair) Description() string {
	// TODO: Use the config values, once they are packaged properly. We currently
	// don't have access to them, due to them being in main pkg.
	return "KD Service"
}

// TODO: Add a connection check
func (r *KlientRunningRepair) Status() (bool, error) {
	if !r.KlientService.IsKlientRunning() {
		return false, errors.New("Klient is not running")
	}

	return true, nil
}

func (r *KlientRunningRepair) Repair() error {
	// In an effort to not only start klient, but *re*start it, we first need to make
	// sure it's stopped. If we're running repair, we already think it's not running,
	// but if we try to stop klient we can be even more confident that it's not running.
	r.KlientService.Stop()

	// The KlientService will wait for klient to be properly starting, so let that
	// start and wait for klient.
	if err := r.KlientService.Start(); err != nil {
		return err
	}

	// For good measure, confirm that klient is running.
	_, err := r.Status()
	return err
}
