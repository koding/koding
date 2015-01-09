package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"os"
	"text/tabwriter"

	"github.com/koding/multiconfig"
	"github.com/mitchellh/goamz/aws"
)

type Config struct {
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

	fmt.Printf("Searching for user VMs in production ...\n")

	// filter := ec2.NewFilter()
	// // filter.Add("tag-value", "production")
	// // filter.Add("key-name", "kloud-deployment")
	// // filter.Add("architecture", "x86_64")
	//
	// t.Filter = filter
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

	fmt.Fprintf(w, "\nTotal instances in all regions: %d", total)

	fmt.Fprintln(w)
	w.Flush()
}
