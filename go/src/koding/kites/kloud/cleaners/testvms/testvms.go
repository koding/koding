package testvms

import (
	"koding/kites/kloud/cleaners/lookup"
	"time"

	"github.com/mitchellh/goamz/aws"
)

func New(auth aws.Auth, envs []string, olderThan time.Duration) *lookup.Lookup {
	return lookup.New(auth, envs, olderThan)
}
