package amazon

import (
	aws "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/logging"
)

type AmazonClient struct {
	*aws.Amazon
	Log           logging.Logger
	Push          func(string, int, machinestate.State)
	CredentialRaw map[string]interface{}
	BuilderRaw    map[string]interface{}
}

func (a *AmazonClient) Initialize() error {
	return nil
}
