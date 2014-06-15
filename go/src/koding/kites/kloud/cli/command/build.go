package command

import (
	"flag"
	"fmt"
	"io/ioutil"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

var (
	machineId string
)

type Build struct {
	flag      *flag.FlagSet
	machineId string
}

func NewBuild() cli.CommandFactory {
	return func() (cli.Command, error) {
		b := &Build{}
		flagSet := flag.NewFlagSet("build", flag.ContinueOnError)
		flagSet.StringVar(&b.machineId, "machine", "", "machine Id to be created")
		flagSet.SetOutput(ioutil.Discard)

		return &Build{
			flag: flagSet,
		}, nil
	}
}

func (b *Build) Synopsis() string { return "Build a machine" }

func (b *Build) Action(args []string, kloud *kite.Client) error {
	fmt.Printf("machineId %+v\n", b.machineId)

	return nil
}

func (b *Build) Help() string {
	help := "usage of build:\n\n"
	b.flag.VisitAll(func(f *flag.Flag) {
		format := "  -%s=%s: %s\n"
		help += fmt.Sprintf(format, f.Name, f.DefValue, f.Usage)
	})

	return help
}

func (b *Build) Run(args []string) int {
	if len(args) == 0 {
		DefaultUi.Info(b.Help())
		return 0
	}

	err := b.flag.Parse(args)
	if err != nil {
		DefaultUi.Error(err.Error())
		return 1
	}

	err = KloudContext(args, b.Action)
	if err != nil {
		return 1
	}

	return 0
}
