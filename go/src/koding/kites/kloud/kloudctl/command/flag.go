package command

import (
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
)

var (
	// global flags variables
	flagRandomKite bool
)

type Flag struct {
	*flag.FlagSet
	name     string
	synopsis string
	action   Actioner
}

func NewFlag(name, synopsis string) *Flag {
	flagSet := flag.NewFlagSet(name, flag.PanicOnError)
	flagSet.SetOutput(ioutil.Discard)

	// global subcommand flags
	flagSet.BoolVar(&flagRandomKite, "random-kite", false, "Choose random kloud instance if there are multiple instances available.")

	f := &Flag{
		name:     name,
		synopsis: synopsis,
	}

	f.FlagSet = flagSet
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
	if f.NumberOfFlags() != 0 && len(args) == 0 {
		fmt.Print(f.Help())
		return errors.New("no arguments")
	}

	err := f.Parse(args)
	if err != nil {
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
