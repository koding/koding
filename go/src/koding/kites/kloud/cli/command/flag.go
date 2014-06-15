package command

import (
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
)

type Flag struct {
	*flag.FlagSet
	name     string
	synopsis string
	action   Actioner
}

func NewFlag(name, synopsis string) *Flag {
	flagSet := flag.NewFlagSet(name, flag.ExitOnError)
	flagSet.SetOutput(ioutil.Discard)

	f := &Flag{
		name:     name,
		synopsis: synopsis,
	}

	f.FlagSet = flagSet
	return f
}

func (f *Flag) Synopsis() string { return f.synopsis }

func (f *Flag) Help() string {
	help := fmt.Sprintf("usage of %s:\n\n", f.name)
	f.VisitAll(func(fl *flag.Flag) {
		format := "  -%s=%s: %s\n"
		help += fmt.Sprintf(format, fl.Name, fl.DefValue, fl.Usage)
	})

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
