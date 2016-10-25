package marathon

import (
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
)

// Stack represents a Marathon application.
type Stack struct {
	*provider.BaseStack
}

var (
	_ provider.Stack = (*Stack)(nil) // public API
	_ stack.Stacker  = (*Stack)(nil) // internal API
)

func newStack(bs *provider.BaseStack) (provider.Stack, error) {
	return &Stack{
		BaseStack: bs,
	}, nil
}

// VerifyCredential checks whether the given credentials
// can be used for deploying an app into Marathon.
func (app *Stack) VerifyCredential(c *stack.Credential) error {
	return nil
}

// BootstrapTemplate implements the provider.Stack interface.
//
// It is a nop for Marathon.
func (s *Stack) BootstrapTemplates(*stack.Credential) (_ []*stack.Template, _ error) {
	return
}

// StacklyTemplate applies the given credentials to user's stack template.
func (s *Stack) ApplyTemplate(c *stack.Credential) (*stack.Template, error) {
	return nil, nil
}

// Credential gives Marathon credentials that are attached
// to a current stack.
func (s *Stack) Credential() *Credential {
	return s.BaseStack.Credential.(*Credential)
}
