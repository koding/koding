package main

import (
	"flag"
	"fmt"
	"koding/kites/kloud/cleaners/testvms"
	"os"
	"text/tabwriter"
	"time"
)

var (
	flagTerminate = flag.Bool("terminate", false, "Terminate all instances")
)

func main() {
	flag.Parse()

	envs := []string{"sandbox", "dev"}

	t := testvms.New(envs, time.Hour*24*7)

	fmt.Printf("Searching for instances tagged with %+v and older than 7 days\n", envs)

	done := make(chan bool)
	go func() {
		t.Process()
		done <- true
	}()

	// check the result every two seconds
	ticker := time.NewTicker(2 * time.Second)
	go func() {
		for _ = range ticker.C {
			fmt.Printf(".  ")
		}
	}()
	<-done
	ticker.Stop()

	fmt.Printf("\n\n")
	w := new(tabwriter.Writer)
	w.Init(os.Stdout, 0, 8, 0, '\t', 0)

	total := 0
	for client, instances := range t.FoundInstances {
		region := client.Region.Name
		fmt.Fprintf(w, "[%s]\t total instances: %+v \n", region, len(instances))
		total += len(instances)
	}

	fmt.Fprintln(w)
	w.Flush()

	if *flagTerminate {
		fmt.Printf("Terminating '%d' instances\n", total)
		t.TerminateAll()
	} else if total > 0 {
		fmt.Printf("To delete all VMs run the command again with the flag -terminate\n")
	}
}
