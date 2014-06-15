package command

import (
	"flag"
	"fmt"
	"io/ioutil"
	"time"

	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

type Build struct {
	flag      *flag.FlagSet
	machineId *string
}

func NewBuild() cli.CommandFactory {
	return func() (cli.Command, error) {
		flagSet := flag.NewFlagSet("build", flag.ContinueOnError)
		flagSet.SetOutput(ioutil.Discard)

		return &Build{
			flag:      flagSet,
			machineId: flagSet.String("machine", "", "machine Id to be created"),
		}, nil
	}
}

func (b *Build) Synopsis() string { return "Build a machine" }

func (b *Build) Action(args []string, k *kite.Client) error {
	bArgs := &kloud.Controller{
		MachineId: *b.machineId,
	}

	resp, err := k.TellWithTimeout("build", time.Second*4, bArgs)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}

	DefaultUi.Info(fmt.Sprintf("%+v", result))
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
		fmt.Print(b.Help())
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
