package control

import (
	"time"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/fix"
)

const (
	// exitDelay is the amount of time `klient.stop` will wait before
	// actually running the uninstall logic. See Stop() docstring for
	// more information.
	exitDelay = 100 * time.Millisecond

	stopCommand     string = "service klient stop"
	overrideCommand string = "touch /etc/init/klient.override"
)

// Stop implements the `klient.stop` method, to stop klient from
// running remotely. This is tightly integrated with Ubuntu, due to
// upstart usage.
//
// It's important to note that Stop() does not (and should not)
// immediately stop klient. Doing so would prevent the caller from
// getting any sort of a response. So, the actual command is delayed
// by the time specified in exitDelay.
//
// TODO: Find a way to stop Klient *after* it has safely finished any
// pre-existing tasks.
func Stop(r *kite.Request) (interface{}, error) {
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
