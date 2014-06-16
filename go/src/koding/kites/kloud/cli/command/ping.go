package command

import (
	"github.com/koding/kite"
	"github.com/mitchellh/cli"
)

func NewPing() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("ping", "Send a test ping message")
		f.action = ActionFunc(PingAction)
		return f, nil

	}
}

func PingAction(args []string, kloud *kite.Client) error {
	resp, err := kloud.Tell("kite.ping")
	if err != nil {
		DefaultUi.Error(err.Error())
	}

	DefaultUi.Info(resp.MustString())
	return nil
}
