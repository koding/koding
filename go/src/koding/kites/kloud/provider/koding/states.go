package koding

import "koding/kites/kloud/machinestate"

type statePair struct {
	initial machinestate.State
	final   machinestate.State
}

var states = map[string]*statePair{
	"build":          &statePair{initial: machinestate.Building, final: machinestate.Running},
	"start":          &statePair{initial: machinestate.Starting, final: machinestate.Running},
	"stop":           &statePair{initial: machinestate.Stopping, final: machinestate.Stopped},
	"destroy":        &statePair{initial: machinestate.Terminating, final: machinestate.Terminated},
	"restart":        &statePair{initial: machinestate.Rebooting, final: machinestate.Running},
	"resize":         &statePair{initial: machinestate.Pending, final: machinestate.Running},
	"reinit":         &statePair{initial: machinestate.Terminating, final: machinestate.Running},
	"createSnapshot": &statePair{initial: machinestate.Snapshotting, final: machinestate.Running},
	"deleteSnapshot": &statePair{initial: machinestate.Snapshotting, final: machinestate.Running},
}
