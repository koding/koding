package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"os"
	"text/tabwriter"
	"time"

	"github.com/koding/multiconfig"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
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

	auth := aws.Auth{
		AccessKey: conf.AccessKey,
		SecretKey: conf.SecretKey,
	}

	t := lookup.New(auth)

	fmt.Printf("Searching for instances tagged with [sandbox, dev] and older than 1 day ...\n")

	filter := ec2.NewFilter()
	filter.Add("tag-value", "sandbox", "dev")
	// Anything except "terminated" and "shutting-down"
	filter.Add("instance-state-name", "pending", "running", "stopping", "stopped")

	t.Filter = filter
	t.OlderThan = time.Hour * 24
	t.FetchInstances()

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
