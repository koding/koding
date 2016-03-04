package main

import (
	"os"
	"os/user"
	"path/filepath"
	"runtime"
)

const (
	// KlientDirectory is full path to directory that holds klient.
	KlientDirectory = "/opt/kite/klient"

	// KlientctlDirectory is full path to directory that holds klientctl.
	KlientctlDirectory = "/usr/local/bin"

	// KlientctlBinName is the bin named that will be stored in the KlientctlDirectory.
	KlientctlBinName = "kd"

	// KontrolURL is the url to connect to authenticate local klient and get
	// list of machines.
	KontrolURL = "https://koding.com/kontrol/kite"

	osName = runtime.GOOS

	// S3UpdateLocation is publically accessible url to check for new updates.
	S3UpdateLocation = "https://koding-kd.s3.amazonaws.com/latest-version.txt"

	// S3KlientPath is publically accessible url for latest version of klient.
	// Each OS has its own version of binary, identifiable by OS suffix.
	S3KlientPath = "https://koding-kd.s3.amazonaws.com/klient-" + osName

	// S3KlientctlPath is publically accessible url for latest version of
	// klientctl. Each OS has its own version of binary, identifiable by suffix.
	S3KlientctlPath = "https://koding-kd.s3.amazonaws.com/klientctl-" + osName

	// SSHDefaultKeyDir is the default directory that stores users ssh key pairs.
	SSHDefaultKeyDir = ".ssh"

	// SSHDefaultKeyName is the default name of the ssh key pair.
	SSHDefaultKeyName = "kd-ssh-key"
)

var (
	// ConfigFolder is folder where config and other related info are stored.
	ConfigFolder string
)

func init() {
	var err error
	if ConfigFolder, err = createFolderAtHome(".config", "koding"); err != nil {
		panic(err)
	}
}

func createFolderAtHome(cf ...string) (string, error) {
	usr, err := user.Current()
	if err != nil {
		return "", err
	}

	args := []string{usr.HomeDir}
	args = append(args, cf...)

	folderName := filepath.Join(args...)
	if err := os.MkdirAll(folderName, 0755); err != nil {
		return "", err
	}

	return folderName, nil
}
