package softlayer_test

import (
	"testing"

	"koding/db/models"
	"koding/kites/kloud/provider/softlayer"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
)

func newBaseMachine() *provider.BaseMachine {
	return &provider.BaseMachine{
		Machine:    &models.Machine{},
		Session:    nil,
		Credential: softlayer.Provider.Schema.NewCredential(),
		Bootstrap:  softlayer.Provider.Schema.NewBootstrap(),
		Metadata:   softlayer.Provider.Schema.NewMetadata(&stack.Machine{}),
		Provider:   "softlayer",
	}
}

func TestNewMachine(t *testing.T) {
	if _, err := softlayer.NewMachine(newBaseMachine()); err != nil {
		t.Fatal(err)
	}
}

func TestMachineStart(t *testing.T) {
	t.Skip("Not implemented!")
}

func TestMachineStop(t *testing.T) {
	t.Skip("Not implemented!")
}

func TestMachineInfo(t *testing.T) {
	t.Skip("Not implemented!")
}
