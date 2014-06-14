package command

import (
	"github.com/codegangsta/cli"
	"github.com/koding/kite"
)

func PingCommand() cli.Command {
	return cli.Command{
		Name:  "ping",
		Usage: "Send a ping message",
		Action: func(c *cli.Context) {
			KloudContext(c, pingAction)
		},
	}
}

func pingAction(c *cli.Context, kloud *kite.Client) {
	resp, err := kloud.Tell("kite.ping")
	if err != nil {
		DefaultUi.Error(err.Error())
	}

	DefaultUi.Info(resp.MustString())
}
