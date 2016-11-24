package softlayer

import (
	"os"
	"strconv"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
)

// Kloud provider that implements handling of Softlayer stacks
var Provider = &provider.Provider{
	Name:         "softlayer",
	ResourceName: "virtual_guest",
	Machine:      NewMachine,
	Stack: func(bs *provider.BaseStack) (provider.Stack, error) {
		s := &Stack{BaseStack: bs}

		bs.SSHKeyPairFunc = s.setSSHKeyPair

		return s, nil
	},
	Schema: &provider.Schema{
		NewCredential: func() interface{} { return &Credential{} },
		NewBootstrap:  func() interface{} { return &Bootstrap{} },
		NewMetadata: func(m *stack.Machine) interface{} {
			meta := &Metadata{}

			if m == nil {
				return meta
			}

			if id, err := strconv.Atoi(m.Attributes["id"]); err == nil {
				meta.Id = id
			}

			return meta
		},
	},
}

func init() {
	// Register Softlayer provider with Koding
	provider.Register(Provider)

	// Makes softlayer-go to not output debug information.
	os.Setenv("NON_VERBOSE", "yes")
}
