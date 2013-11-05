// +build linux

// Copyright © 2013, S.Çağlar Onur
// Use of this source code is governed by a LGPLv2.1
// license that can be found in the LICENSE file.
//
// Authors:
// S.Çağlar Onur <caglar@10ur.org>

// +build linux

package lxc

// #include <lxc/lxc.h>
// #include <lxc/lxccontainer.h>
import "C"

type State int

const (
	STOPPED  State = C.STOPPED
	STARTING State = C.STARTING
	RUNNING  State = C.RUNNING
	STOPPING State = C.STOPPING
	ABORTING State = C.ABORTING
	FREEZING State = C.FREEZING
	FROZEN   State = C.FROZEN
	THAWED   State = C.THAWED
)

var stateMap = map[string]State{
	"STOPPED":  STOPPED,
	"STARTING": STARTING,
	"RUNNING":  RUNNING,
	"STOPPING": STOPPING,
	"ABORTING": ABORTING,
	"FREEZING": FREEZING,
	"FROZEN":   FROZEN,
	"THAWED":   THAWED,
}

// State as string
func (t State) String() string {
	switch t {
	case STOPPED:
		return "STOPPED"
	case STARTING:
		return "STARTING"
	case RUNNING:
		return "RUNNING"
	case STOPPING:
		return "STOPPING"
	case ABORTING:
		return "ABORTING"
	case FREEZING:
		return "FREEZING"
	case FROZEN:
		return "FROZEN"
	case THAWED:
		return "THAWED"
	}
	return "<INVALID>"
}
