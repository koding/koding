// +build !windows

package terminal

import (
	"syscall"

	"koding/klient/terminal/pty"

	"github.com/koding/kite/dnode"
)

// Server is the type of object that is sent to the connected client.
// Represents a running shell process on the server.
type Server struct {
	Session string `json:"session"`

	// never expose the following fields as we return them back to the client.
	// Dnode is decoding it and client side get mad about it.
	remote Remote
	pty    *pty.PTY

	currentSecond    int64
	messageCounter   int
	byteCounter      int
	lineFeeedCounter int
	throttling       bool

	// inputHook is called whenever an input is received
	inputHook func()
}

type Remote struct {
	Output       dnode.Function
	SessionEnded dnode.Function
}

// Input is called when some text is written to the terminal.
func (s *Server) Input(d *dnode.Partial) {
	data := d.MustSliceOfLength(1)[0].MustString()

	if s.inputHook != nil {
		s.inputHook()
	}

	// There is no need to protect the Write() with a mutex because
	// Kite Library guarantees that only one message is processed at a time.
	s.pty.Master.Write([]byte(data))
}

// ControlSequence is called when a non-printable key is pressed on the terminal.
func (s *Server) ControlSequence(d *dnode.Partial) {
	data := d.MustSliceOfLength(1)[0].MustString()
	s.pty.MasterEncoded.Write([]byte(data))
}

func (s *Server) SetSize(d *dnode.Partial) {
	args := d.MustSliceOfLength(2)
	x := args[0].MustFloat64()
	y := args[1].MustFloat64()
	s.setSize(x, y)
}

func (s *Server) setSize(x, y float64) {
	s.pty.SetSize(uint16(x), uint16(y))
}

func (s *Server) Close(d *dnode.Partial) {
	s.pty.Signal(syscall.SIGHUP)
}

func (s *Server) Terminate(d *dnode.Partial) {
	s.Close(nil)
}
