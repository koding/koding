// config package contains reused config variables.
package config

import (
	"fmt"
	"path/filepath"
)

const (
	// Name is the user facing name for this binary. Internally we call it
	// klientctl to avoid confusion.
	Name = "kd"

	// KlientName is the user facing name for klient.
	KlientName = "KD Daemon"

	// KlientAddress is url of locally running klient to connect to send
	// user commands.
	KlientAddress = "http://127.0.0.1:56789/kite"

	// KiteHome is full path to the kite key that we will use to authenticate
	// to the given klient.
	KiteHome = "/etc/kite"

	// Version is the current version of klientctl. This number is used
	// by CheckUpdate to determine if current version is behind or equal to latest
	// version on S3 bucket.
	Version = 25

	// SSHDefaultKeyDir is the default directory that stores users ssh key pairs.
	SSHDefaultKeyDir = ".ssh"

	// SSHDefaultKeyName is the default name of the ssh key pair.
	SSHDefaultKeyName = "kd-ssh-key"
)

var (
	// KiteVersion is the version identifier used to connect to Kontrol.
	KiteVersion = fmt.Sprintf("0.0.%d", Version)

	// KiteKeyPath is the full path to kite.key.
	KiteKeyPath = filepath.Join(KiteHome, "kite.key")
)
