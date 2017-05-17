// Package marathon implements Kloud provider for Marathon:
//
//   https://mesosphere.github.io/marathon/
//
// The provider interfaces with Marathon API using
// a Terraform provider:
//
//   https://github.com/Banno/terraform-provider-marathon
//
// The consequence is that application state is managed
// through Terraform template changes, so it does not
// use Marathon auto-scaling features.
package marathon

import "koding/kites/kloud/stack/provider"

func init() {
	provider.Register(&provider.Provider{
		Name:         "marathon",
		ResourceName: "app",
		NoCloudInit:  true,
		Userdata:     "cmd",
		Machine:      newMachine,
		Stack:        newStack,
		Schema:       schema,
	})
}
