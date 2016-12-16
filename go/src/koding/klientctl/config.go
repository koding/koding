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

	// TODO(rjeczalik): add support for initializing configuration via
	// fetching it from kloud url passed as argument

	k, ok := configstore.List()[c.Args().Get(0)]
	if !ok {
		fmt.Fprintf(os.Stderr, "Configuration %q was not found. Please use \"kd config list\""+
			" to list available configurations.\n", c.Args().Get(0))
		return 1, nil
	}

	if err := configstore.Use(k); err != nil {
		fmt.Fprintln(os.Stderr, "Error switching configuration:", err)
		return 1, err
	}

	fmt.Printf("Switched to %s.\n", k.Endpoints.Koding.Public)

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
