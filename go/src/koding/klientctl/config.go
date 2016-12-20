package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"text/tabwriter"
	"time"

	konfig "koding/kites/config"
	"koding/kites/config/configstore"
	"koding/kites/kloud/utils/object"
	"koding/klient/storage"
	"koding/klientctl/config"
	cfg "koding/klientctl/endpoint/config"

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
	Tag:           "json",
	Sep:           ".",
	Recursive:     true,
	FlatStringers: true,
}

func ConfigShow(c *cli.Context, log logging.Logger, _ string) (int, error) {
	used := config.Konfig

	if !c.Bool("defaults") {
		k, err := cfg.Used()
		if err != nil && err != storage.ErrKeyNotFound {
			return 1, err
		}
		if err == nil {
			used = k
		}
	}

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "\t")
		enc.Encode(used)

		return 0, nil
	}

	printKonfig(used)

	return 0, nil
}

func ConfigSet(c *cli.Context, log logging.Logger, _ string) (int, error) {
	if len(c.Args()) != 2 {
		cli.ShowCommandHelp(c, "set")
		return 1, nil
	}

	if err := configstore.Set(c.Args().Get(0), c.Args().Get(1)); err != nil {
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

	if err := configstore.Set(c.Args().Get(0), ""); err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1, err
	}

	return 0, nil
}

func ConfigList(c *cli.Context, log logging.Logger, _ string) (int, error) {
	konfigs := configstore.List()

	if c.Bool("json") {
		p, err := json.MarshalIndent(konfigs, "", "\t")
		if err != nil {
			return 1, err
		}

		fmt.Printf("%s\n", p)

		return 0, nil
	}

	printKonfigs(konfigs.Slice())

	return 0, nil
}

func ConfigUse(c *cli.Context, log logging.Logger, _ string) (int, error) {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "use")
		return 1, nil
	}

	arg := c.Args().Get(0)

	k, ok := configstore.List()[arg]
	if !ok {
		fmt.Fprintf(os.Stderr, "Configuration %q was not found. Please use \"kd config list"+
			"\" to list available configurations.\n", arg)
		return 1, nil
	}

	if err := configstore.Use(k); err != nil {
		fmt.Fprintln(os.Stderr, "Error switching configuration:", err)
		return 1, err
	}

	fmt.Printf("Switched to %s.\n\nPlease run \"sudo kd restart\" for the new configuration to take effect.\n", k.KodingPublic())

	return 0, nil
}

func ConfigReset(c *cli.Context, log logging.Logger, _ string) (int, error) {
	if err := cfg.Reset(); err != nil {
		fmt.Fprintln(os.Stderr, "Error resetting configuration:", err)
		return 1, err
	}

	fmt.Printf("Reset %s.\n\nPlease run \"sudo kd restart\" for the new configuration to take effect.\n", config.Konfig.KodingPublic())

	return 0, nil
}

func printKonfigs(konfigs []*konfig.Konfig) {
	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "ID\tKODING URL")

	for _, konfig := range konfigs {
		fmt.Fprintf(w, "%s\t%s\n", konfig.ID(), konfig.KodingPublic())
	}
}

func printKonfig(konfig *konfig.Konfig) {
	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "KEY\tVALUE")

	obj := b.Build(konfig, "kiteKey", "kontrolURL", "tunnelURL")

	for _, key := range obj.Keys() {
		value := obj[key]
		if value == nil || fmt.Sprintf("%v", value) == "" {
			value = "-"
		}
		fmt.Fprintf(w, "%s\t%v\n", key, value)
	}
}
