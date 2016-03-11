package command

import "github.com/mitchellh/cli"

func NewPing() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("ping", "Send a test ping message")
		f.action = ActionFunc(PingAction)
		return f, nil

	}
}

func PingAction(args []string) error {
	k, err := kloudClient()
	if err != nil {
		return err
	}
	resp, err := k.Tell("kite.ping")
	if err != nil {
		return err
	}

	DefaultUi.Info(resp.MustString())
	return nil
}
