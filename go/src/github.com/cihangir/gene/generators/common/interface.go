package common

import "github.com/cihangir/schema"

// Req holds request data for rpc calls
type Req struct {
	Schema    *schema.Schema
	SchemaStr string
	Context   *Context
}

// Res holds response for rpc calls
type Res struct {
	Output []Output
}

// Generator is the basic interface for plugin operations.
type Generator interface {
	Generate(*Req, *Res) error
}
