package testvms

import (
	"fmt"
	"koding/kites/kloud/multiec2"

	"github.com/mitchellh/goamz/aws"
)

type testvms struct {
	// tags contains a list of instance tags that are identified as test
	// instances
	tag    string
	values []string

	clients *multiec2.Clients
}

func New() *testvms {
	// Credential belongs to the `koding-kloud` user in AWS IAM's
	auth := aws.Auth{
		AccessKey: "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey: "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",
	}

	return &testvms{
		tag:    "koding-env",
		values: []string{"sandbox", "development"},
		clients: multiec2.New(auth, []string{
			"us-east-1",
			"ap-southeast-1",
			"us-west-2",
			"eu-west-1",
		}),
	}
}

// Process fetches all instances defined with the tags
func (t *testvms) Process() {

	for region, client := range t.clients.Regions() {
		fmt.Printf("region = %+v\n", region)
		fmt.Printf("client = %+v\n", client)
	}

}

func (t *testvms) Summary() {

}
