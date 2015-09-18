package main

import (
	"log"
	"os"

	"github.com/mitchellh/cli"
)

func main() {
	c := cli.NewCLI(Name, Version)
	c.Args = os.Args[1:]

	kc, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		log.Fatal(err)
	}

	c.Commands = map[string]cli.CommandFactory{
		"list":    ListCommandFactory(kc),
		"mount":   MountCommandFactory(kc),
		"unmount": UnmountCommandFactory(kc),
	}

	if _, err = c.Run(); err != nil {
		log.Fatal(err)
	}
}
