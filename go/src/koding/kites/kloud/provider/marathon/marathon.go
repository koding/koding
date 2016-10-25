package marathon

import "koding/kites/kloud/stack/provider"

func init() {
	provider.Register(&provider.Provider{
		Name:         "marathon",
		ResourceName: "app",
		Machine:      newMachine,
		Stack:        newStack,
		Schema:       schema,
	})
}
