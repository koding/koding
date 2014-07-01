package openstack

import (
	"koding/kites/kloud/kloud/machinestate"
	"strings"
)

// statusToState converts a rackspacke status to a sensible machinestate.State
// format
func statusToState(status string) machinestate.State {
	status = strings.ToLower(status)

	switch status {
	case "active":
		return machinestate.Running
	case "suspended":
		return machinestate.Stopped
	case "build", "rebuild":
		return machinestate.Building
	case "deleted":
		return machinestate.Terminated
	case "hard_reboot", "reboot":
		return machinestate.Rebooting
	case "migrating", "password", "resize":
		return machinestate.Updating
	default:
		return machinestate.Unknown
	}
}
