package command

import (
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
)

var (
	// global flags variables
	flagWatchEvents bool
	flagKloudAddr   string
	flagUsername    string
	flagDebug       bool
)

type Flag struct {
	*flag.FlagSet
	name     string
	synopsis string
	action   Actioner

	totalDefaultFlag int
}

func NewFlag(name, synopsis string) *Flag {
	flagSet := flag.NewFlagSet(name, flag.ContinueOnError)
	flagSet.SetOutput(ioutil.Discard)

	// global subcommand flags
	flagSet.StringVar(&flagKloudAddr, "kloud-addr", "http://127.0.0.1:5500/kite",
		"Kloud addr to connect")
	flagSet.BoolVar(&flagWatchEvents, "watch", false, "Watch the events coming by.")
	flagSet.BoolVar(&flagDebug, "debug", false, "Turns on debug logging.")

	f := &Flag{
		name:     name,
		synopsis: synopsis,
	}

	f.FlagSet = flagSet
	f.totalDefaultFlag = f.NumberOfFlags()
	return f
}

func (f *Flag) Synopsis() string { return f.synopsis }

func (f *Flag) Help() string {
	help := fmt.Sprintf("usage: kloudctl %s [<args>]\n\n", f.name)
	help += f.synopsis + "\n\n"
	f.VisitAll(func(fl *flag.Flag) {
		format := "  -%s=%s: %s\n"
		help += fmt.Sprintf(format, fl.Name, fl.DefValue, fl.Usage)
	})

	help += "\n"

	return help
}

func (f *Flag) NumberOfFlags() int {
	count := 0
	f.VisitAll(func(fl *flag.Flag) {
		count++
	})

	return count
}

func (f *Flag) ParseArgs(args []string) error {
	// If there are some flags defined and the user didnt' provide any flag
	// let us report it
	cmdFlagCount := f.NumberOfFlags() - f.totalDefaultFlag

	if cmdFlagCount > len(args) {
		fmt.Print(f.Help())
		return errors.New("no arguments")
	}

	err := f.Parse(args)
	if err != nil && err != flag.ErrHelp {
		DefaultUi.Error(err.Error())
		return err
	}

	return nil
}

func (f *Flag) Run(args []string) int {
	err := f.ParseArgs(args)
	if err != nil {
		return 1
	}

	err = kloudWrapper(args, f.action)
	if err != nil {
		return 1
	}

	return 0
}
