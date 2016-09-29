package vagrant_test

import (
	"koding/kites/kloud/provider/vagrant"
	"koding/kites/kloud/stack"
)

var (
	_ stack.Stacker  = (*vagrant.Stack)(nil)
	_ stack.Machiner = (*vagrant.Machine)(nil)
)
