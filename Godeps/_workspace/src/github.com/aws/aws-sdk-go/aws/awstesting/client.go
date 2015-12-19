package awstesting

import (
	"github.com/koding/klient/Godeps/_workspace/src/github.com/aws/aws-sdk-go/aws"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/aws/aws-sdk-go/aws/client"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/aws/aws-sdk-go/aws/client/metadata"
	"github.com/koding/klient/Godeps/_workspace/src/github.com/aws/aws-sdk-go/aws/defaults"
)

// NewClient creates and initializes a generic service client for testing.
func NewClient(cfgs ...*aws.Config) *client.Client {
	info := metadata.ClientInfo{
		Endpoint:    "http://endpoint",
		SigningName: "",
	}
	def := defaults.Get()
	def.Config.MergeIn(cfgs...)

	return client.New(*def.Config, info, def.Handlers)
}
