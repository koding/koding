package command

import (
	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

func NewBuild() cli.CommandFactory {
	return func() (cli.Command, error) {
		return &Build{}, nil
	}
}

type Build struct{}

func (b *Build) Help() string {
	return "Build builds a new machine for the given id."
}

func (b *Build) Run(args []string) int {
	if len(args) == 0 {
		DefaultUi.Info(b.Help())
		return 0
	}

	KloudContext(args, buildAction)
	return 0
}

func (b *Build) Synopsis() string { return "Build a machine" }

func buildAction(args []string, kloud *kite.Client) {
	DefaultUi.Output("Not implemented")
}
