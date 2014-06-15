package command

import (
	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

func NewPing() cli.CommandFactory {
	return func() (cli.Command, error) {
		return &Ping{}, nil
	}
}

type Ping struct{}

func (p *Ping) Help() string { return "Send a ping message" }

func (p *Ping) Run(args []string) int {
	err := KloudContext(args, pingAction)
	if err != nil {
		return 1
	}

	return 0
}

func (p *Ping) Synopsis() string { return "Send a ping message" }

func pingAction(args []string, kloud *kite.Client) error {
	resp, err := kloud.Tell("kite.ping")
	if err != nil {
		DefaultUi.Error(err.Error())
	}

	DefaultUi.Info(resp.MustString())
	return nil
}
