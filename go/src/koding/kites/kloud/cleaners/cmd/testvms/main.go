package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/testvms"
	"os"
	"text/tabwriter"
	"time"

	"github.com/koding/multiconfig"
	"github.com/mitchellh/goamz/aws"
)

type Config struct {
	Terminate bool

	// AWS Access and Secret Key
	AccessKey string `required:"true"`
	SecretKey string `required:"true"`
}

func main() {
	conf := new(Config)

	// Load the config, it's reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	envs := []string{"sandbox", "dev"}

	auth := aws.Auth{
		AccessKey: conf.AccessKey,
		SecretKey: conf.SecretKey,
	}

	t := testvms.New(auth, envs, time.Hour*24)

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

	if conf.Terminate {
		t.TerminateAll()
		fmt.Printf("Terminated '%d' instances\n", total)
	} else if total > 0 {
		fmt.Printf("To delete all VMs run the command again with the flag -terminate\n")
	}
}
