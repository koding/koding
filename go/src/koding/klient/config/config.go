// Protocol is a package that klient and several other packages uses. It
// contains the information which is passed to the kite library during booting.
// They are a part of the KiteQuery and are populated via go build and using
// the -ldflags feature.
package config

import konfig "koding/kites/config"

var (
	Version     string
	Environment string
)

const (
	Name   = "klient"
	Region = "public-region"
)

// Konfig represents a klient configuration.
var Konfig = ReadKonfig()

// ReadKonfig reads klient configuration.
func ReadKonfig() *konfig.Konfig {
	return konfig.ReadKonfig(&konfig.Environments{
		Env: Environment,
	})
}
