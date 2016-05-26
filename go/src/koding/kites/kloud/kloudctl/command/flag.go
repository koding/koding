package command

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"
)

var (
	// global flags variables
	flagWatchEvents bool
	flagKontrolURL  string
	flagDebug       bool
)

type Flag struct {
	*flag.FlagSet
	name     string
	synopsis string
	action   Actioner

	totalDefaultFlag int
}

func defaultKontrolURL() string {
	if s := os.Getenv("KITE_KONTROL_URL"); s != "" {
		return s
	}
	return "https://koding.com/kontrol/kite"
}

func defaultDebug() bool {
	return os.Getenv("KLOUDCTL_DEBUG") == "1"
}

func NewFlag(name, synopsis string) *Flag {
	flagSet := flag.NewFlagSet(name, flag.ContinueOnError)
	flagSet.SetOutput(ioutil.Discard)

	// global subcommand flags
	flagSet.StringVar(&flagKontrolURL, "kontrol-url", defaultKontrolURL(),
		"Kontrol URL.")
	flagSet.BoolVar(&flagWatchEvents, "watch", false, "Watch the events coming by.")
	flagSet.BoolVar(&flagDebug, "debug", defaultDebug(), "Turns on debug logging.")

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
