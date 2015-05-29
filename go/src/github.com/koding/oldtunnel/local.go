package tunnel

import (
	"time"

	"github.com/koding/tunnel/conn"
)

// local defines a local connection from client
type local struct {
	*conn.Conn
}

func newLocalDial(addr string) (*local, error) {
	l := &local{}

	c, err := conn.Dial(addr, false)
	if err != nil {
		return nil, err
	}

	l.Conn = c
	l.SetDeadline(time.Time{})
	return l, nil
}
