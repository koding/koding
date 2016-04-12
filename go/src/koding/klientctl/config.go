package main

import (
	"os"
	"os/user"
	"path/filepath"
	"time"
)

const (
	// KlientDirectory is full path to directory that holds klient.
	KlientDirectory = "/opt/kite/klient"

	// KlientctlDirectory is full path to directory that holds klientctl.
	KlientctlDirectory = "/usr/local/bin"

	// KlientctlBinName is the bin named that will be stored in the KlientctlDirectory.
	KlientctlBinName = "kd"

	// CommandAttempts is the number of attempts to try commands like start, stop
	// etc.
	CommandAttempts = 30

	// CommandWaitTime is how long to wait for commands like start, stop to
	// complete
	CommandWaitTime = 1 * time.Second
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
