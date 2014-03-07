package kodingkite

import (
	"github.com/koding/kite"
	"github.com/koding/kite/logging"
	"koding/tools/config"
	"log"
)

// New returns a new kite instance based on for the given Koding configurations
func New(config *config.Config, options kite.Options) *kite.Kite {
	// Update config
	options.Environment = config.Environment

	o := kite.Options(options)
	k := kite.New(&o)

	syslog, err := logging.NewSyslogBackend(options.Kitename)
	if err != nil {
		log.Fatalf("Cannot connect to syslog: %s", err.Error())
	}

	k.Log.SetBackend(logging.NewMultiBackend(logging.StderrBackend, syslog))

	return k
}
