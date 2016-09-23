package stackplan

import (
	"koding/kites/kloud/stack"

	"golang.org/x/net/context"
)

func (bm *BaseMachine) HandleStart(context.Context) error {
	return nil
}

func (bm *BaseMachine) HandleStop(context.Context) error {
	return nil
}

func (bm *BaseMachine) HandleInfo() (*stack.InfoResponse, error) {
	return nil, nil
}
