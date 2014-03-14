package kodingkite

import (
	"koding/tools/config"
	"log"

	"github.com/koding/kite/simple"
	"github.com/koding/logging"
)

// New returns a new kite instance based on for the given Koding configurations
func New(config *config.Config, name, version string) *simple.Simple {
	k := simple.New(name, version)
	k.Config.Environment = config.Environment

	syslog, err := logging.NewSyslogHandler(name)
	if err != nil {
		log.Fatalf("Cannot connect to syslog: %s", err.Error())
	}

	k.Log.SetHandler(logging.NewMultiHandler(logging.StderrHandler, syslog))

	return k
}
