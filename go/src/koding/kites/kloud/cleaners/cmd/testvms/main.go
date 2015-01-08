package main

import (
	"flag"
	"koding/kites/kloud/cleaners/testvms"
	"time"
)

var (
	flagDryRun = flag.Bool("dry-run", true, "Run safely without terminating")
)

func main() {
	flag.Parse()
	t := testvms.New(
		[]string{"sandbox", "dev"},
		time.Hour*24*7,
		*flagDryRun,
	)

	t.Process()
}
