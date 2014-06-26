// Protocol is a package that klient and several other packages uses. It
// contains the information which is passed to the kite library during booting.
// They are a part of the KiteQuert.
package protocol

var (
	Version string
)

const (
	Name        = "klient"
	Environment = "public-host"
	Region      = "public-region"
)
