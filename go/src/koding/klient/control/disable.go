package control

import (
	"errors"
	"fmt"
	"runtime"
	"time"

	konfig "koding/klient/config"
	"koding/klient/fix"

	"github.com/koding/kite"
)

const (
	// exitDelay is the amount of time `klient.stop` will wait before
	// actually running the uninstall logic. See Stop() docstring for
	// more information.
	exitDelay = 100 * time.Millisecond

	stopCommand     string = "service klient stop"
	overrideCommand string = "touch /etc/init/klient.override"
)

// Disable implements the `klient.disable` method, to stop klient
// from running remotely. This is tightly integrated with Ubuntu, due to
// upstart usage.
//
// It's important to note that Disable() does not (and should not)
// immediately stop klient. Doing so would prevent the caller from
// getting any sort of a response. So, the actual command is delayed
// by the time specified in exitDelay.
//
// TODO: Find a way to stop Klient *after* it has safely finished any
// pre-existing tasks.
func Disable(r *kite.Request) (interface{}, error) {
	if konfig.Environment != "managed" && konfig.Environment != "devmanaged" {
		return nil, errors.New(fmt.Sprintf(
			"klient.disable cannot be run from the '%s' Environment",
			konfig.Environment,
		))
	}

	if runtime.GOOS != "linux" {
		return nil, errors.New("klient.disable requires a linux GOOS")
	}

	err := fix.RunAsSudo(overrideCommand)
	if err != nil {
		return nil, err
	}

	go func() {
		time.Sleep(exitDelay)
		fix.RunAsSudo(stopCommand)
	}()

	return nil, nil
}
