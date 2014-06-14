package command

import (
	"fmt"

	"github.com/codegangsta/cli"
)

func BuildCommand() cli.Command {
	return cli.Command{
		Name:  "build",
		Usage: "build a machine",
		Action: func(c *cli.Context) {
			fmt.Println("build todo")
		},
	}
}
