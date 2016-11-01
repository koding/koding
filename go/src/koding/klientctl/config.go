package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"

	konfig "koding/kites/config"
	"koding/kites/kloud/utils/object"
	"koding/klient/storage"
	"koding/klientctl/config"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
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
	args := []string{konfig.CurrentUser.HomeDir}
	args = append(args, cf...)

	folderName := filepath.Join(args...)
	if err := os.MkdirAll(folderName, 0755); err != nil {
		return "", err
	}

	return folderName, nil
}

var b = &object.Builder{
	Tag:       "json",
	Sep:       ".",
	Recursive: true,
}

func ConfigShow(c *cli.Context, log logging.Logger, _ string) (int, error) {
	cfg := config.Konfig

	if !c.Bool("defaults") {
		cfg = &konfig.Konfig{}

		db := konfig.NewCache(konfig.KonfigCache)
		defer db.Close()

		if err := db.GetValue("konfig", cfg); err != nil && err != storage.ErrKeyNotFound {
			return 1, err
		}
	}

	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "\t")

	if err := enc.Encode(cfg); err != nil {
		return 1, err
	}

	return 0, nil
}

func ConfigSet(c *cli.Context, log logging.Logger, _ string) (int, error) {
	if len(c.Args()) != 2 {
		cli.ShowCommandHelp(c, "set")
		return 1, nil
	}

	if err := updateKonfigCache(c.Args().Get(0), c.Args().Get(1)); err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1, err
	}

	return 0, nil
}

func ConfigUnset(c *cli.Context, log logging.Logger, _ string) (int, error) {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "unset")
		return 1, nil
	}

	if err := updateKonfigCache(c.Args().Get(0), nil); err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1, err
	}

	return 0, nil
}

func updateKonfigCache(key string, value interface{}) error {
	db := konfig.NewCache(konfig.KonfigCache)
	defer db.Close()

	var cfg konfig.Konfig

	if err := db.GetValue("konfig", &cfg); err != nil && err != storage.ErrKeyNotFound {
		return fmt.Errorf("failed to update %s=%v: %s", key, value, err)
	}

	if err := b.Set(&cfg, key, value); err != nil {
		return fmt.Errorf("failed to updat %s=%v: %s", key, value, err)
	}

	if err := db.SetValue("konfig", &cfg); err != nil {
		return fmt.Errorf("failed to update %s=%v: %s", key, value, err)
	}

	return nil
}
