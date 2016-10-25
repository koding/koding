package marathon

import (
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
)

var schema = &provider.Schema{
	NewCredential: func() interface{} {
		return &Credential{}
	},
	NewBootstrap: nil,
	NewMetadata: func(m *stack.Machine) interface{} {
		if m == nil {
			return &Metadata{}
		}

		meta := &Metadata{}

		return meta
	},
}

var (
	_ stack.Validator = (*Credential)(nil)
	_ stack.Validator = (*Metadata)(nil)
)

// Credential represents credential information
// that are required to deploy a Marathon app.
type Credential struct {
}

// Valid implements the stack.Validator interface.
func (c *Credential) Valid() error {
	return nil
}

// Metadata represents a single app metadata.
type Metadata struct {
}

// Valid implements the stack.Validator interface.
func (m *Metadata) Valid() error {
	return nil
}
