package stackplan

import (
	"koding/kites/kloud/stack"

	"golang.org/x/net/context"
)

func (bm *BaseMachine) Start(context.Context) error {
	return nil
}

func (bm *BaseMachine) Stop(context.Context) error {
	return nil
}

func (bm *BaseMachine) Info() (*stack.InfoResponse, error) {
	return nil, nil
}
