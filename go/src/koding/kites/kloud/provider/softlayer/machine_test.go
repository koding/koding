package softlayer_test

import (
	"os"
	"testing"

	"koding/db/models"
	"koding/kites/kloud/provider/softlayer"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"

	"golang.org/x/net/context"
)

func newBaseMachine() *provider.BaseMachine {
	return &provider.BaseMachine{
		Machine: &models.Machine{},
		Session: nil,
		Credential: &softlayer.Credential{
			Username: os.Getenv("SL_USERNAME"),
			ApiKey:   os.Getenv("SL_API_KEY"),
		},
		Bootstrap: softlayer.Provider.Schema.NewBootstrap(),
		Metadata: softlayer.Provider.Schema.NewMetadata(&stack.Machine{
			Attributes: map[string]string{
				"id": os.Getenv("SL_GUEST_ID"),
			},
		}),
		Provider: "softlayer",
	}
}

func TestNewMachine(t *testing.T) {
	if _, err := softlayer.NewMachine(newBaseMachine()); err != nil {
		t.Fatal(err)
	}
}

func TestMachineStart(t *testing.T) {
	m, _ := softlayer.NewMachine(newBaseMachine())

	c := context.Background()
	_, err := m.Start(c)
	if err != nil {
		t.Fatal(err)
	}
}

func TestMachineStop(t *testing.T) {
	m, _ := softlayer.NewMachine(newBaseMachine())

	c := context.Background()
	_, err := m.Stop(c)
	if err != nil {
		t.Fatal(err)
	}
}

func TestMachineInfo(t *testing.T) {
	m, _ := softlayer.NewMachine(newBaseMachine())

	c := context.Background()
	_, _, err := m.Info(c)
	if err != nil {
		t.Fatal(err)
	}
}
