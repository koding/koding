package main

import (
	"flag"
	"fmt"
	"koding/kites/kloud/cleaners/testvms"
	"time"
)

var (
	flagTerminate = flag.Bool("-terminate", false, "Terminate all instances")
)

func main() {
	flag.Parse()
	t := testvms.New(
		[]string{"sandbox", "dev"},
		time.Hour*24*7,
	)

	fmt.Printf("Searching for instances tagged with %+v and older than: %s\n\n",
		t.values, t.olderThan)

	t.Process()

	if *flagTerminate {
		t.TerminateAll()
	} else {
		fmt.Printf("\nTo delete all VMs run the command with -terminate again\n")
	}
}
