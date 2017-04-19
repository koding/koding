// Protocol is a package that klient and several other packages uses. It
// contains the information which is passed to the kite library during booting.
// They are a part of the KiteQuery and are populated via go build and using
// the -ldflags feature.
package config

import (
	konfig "koding/kites/config"
	"koding/kites/config/configstore"
)

var (
	Version     string
	Environment string
)

const (
	Name   = "klient"
	Region = "public-region"
)

var envs *konfig.Environments

// Konfig represents a klient configuration.
var Konfig *konfig.Konfig

// Builtin represents a builtin configuration.
var Builtin *konfig.Konfig

// ReadKonfig reads klient configuration.
func ReadKonfig() *konfig.Konfig {
	return configstore.Read(envs)
}

func init() {
	envs = &konfig.Environments{
		Env: Environment,
	}

	Builtin = konfig.NewKonfig(envs)

	Konfig = ReadKonfig()
}
