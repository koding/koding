package terminal

import "github.com/koding/kite"

// Terminal provides kite handler implementation for webterm.* methods.
type Terminal interface {
	GetSessions(*kite.Request) (interface{}, error)
	Connect(*kite.Request) (interface{}, error)
	KillSession(*kite.Request) (interface{}, error)
	KillSessions(*kite.Request) (interface{}, error)
	RenameSession(*kite.Request) (interface{}, error)
	CloseSessions(string)
}

// New creates new webterm.* kite handler.
func New(log kite.Logger, screenrc string, hook func()) Terminal {
	return newTerminal(log, screenrc, hook)
}
