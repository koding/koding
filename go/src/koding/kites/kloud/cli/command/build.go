package command

import (
	"fmt"
	"log"

	"github.com/codegangsta/cli"
	"github.com/koding/kite"
)

func BuildCommand() cli.Command {
	return cli.Command{
		Name:  "build",
		Usage: "Build a new machine based on the given machine id.",
		Flags: []cli.Flag{
			cli.StringFlag{"machine, m", "", "Machine id to be build"},
		},
		Action: func(c *cli.Context) {
			KloudContext(c, buildAction)
		},
	}
}

func buildAction(c *cli.Context, k *kite.Client) {
	// k := c.GlobalString("kontrol")
	// fmt.Printf("k %+v\n", k)
	//
	// m := c.String("machine")
	// fmt.Printf("m %+v\n", m)
	//
	// d := c.GlobalBool("debug")
	// fmt.Printf("d %+v\n", d)

	fmt.Println("Build ..")

	resp, err := k.Tell("kite.ping")
	if err != nil {
		log.Fatalln(err)
	}

	fmt.Println(resp.MustString())
}
