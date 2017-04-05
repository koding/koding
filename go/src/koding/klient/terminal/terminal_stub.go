// +build windows

package terminal

import "github.com/koding/kite"

var errNotImplemented = &kite.Error{
	Type:    "webterm",
	Message: "not implemented",
	CodeVal: "901",
}

type stub struct{}

func (stub) GetSessions(*kite.Request) (interface{}, error)   { return nil, errNotImplemented }
func (stub) Connect(*kite.Request) (interface{}, error)       { return nil, errNotImplemented }
func (stub) RenameSession(*kite.Request) (interface{}, error) { return nil, errNotImplemented }
func (stub) KillSession(*kite.Request) (interface{}, error)   { return nil, errNotImplemented }
func (stub) KillSessions(*kite.Request) (interface{}, error)  { return nil, errNotImplemented }
func (stub) CloseSessions(string)                             {}

func newTerminal(kite.Logger, string, func()) Terminal { return stub{} }
