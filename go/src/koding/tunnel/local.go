package tunnel

import (
	"koding/tunnel/conn"
)

// local defines a local connection from client
type local struct {
	*conn.Conn
}

func newLocalDial(addr string) *local {
	l := &local{}
	l.Conn = conn.Dial(addr, true)
	return l
}
