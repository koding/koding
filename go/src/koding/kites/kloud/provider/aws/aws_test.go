package aws_test

import (
	"koding/kites/kloud/provider/aws"
	"koding/kites/kloud/stack"
)

var (
	_ stack.Machiner = (*aws.Machine)(nil)
	_ stack.Stacker  = (*aws.Stack)(nil)
)
