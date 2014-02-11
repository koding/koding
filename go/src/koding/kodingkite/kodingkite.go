package kodingkite

import (
	"kite"
	"koding/tools/config"
)

// New returns a new kite instance based on for the given Koding configurations
func New(config *config.Config, options kite.Options) *kite.Kite {
	// Update config
	options.Environment = config.Environment

	o := kite.Options(options)
	return kite.New(&o)
}
