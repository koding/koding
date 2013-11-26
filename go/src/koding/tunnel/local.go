package tunnel

import (
	"koding/tunnel/conn"
	"time"
)

// local defines a local connection from client
type local struct {
	*conn.Conn
}

func newLocalDial(addr string) *local {
	l := &local{}
	l.Conn = conn.Dial(addr, false)
	l.SetDeadline(time.Time{})
	return l
}
