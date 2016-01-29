package docker

import (
	"fmt"
	"io"

	dockerclient "github.com/fsouza/go-dockerclient"
	"github.com/koding/kite/dnode"
)

// Server is the type of object that is sent to the connected client.
// Represents a running shell process on the server.
type Server struct {
	Session string `json:"session"`

	// never expose the following fields as we return them back to the client.
	// Dnode is decoding it and client side get mad about it.
	remote Remote

	out             io.Reader
	in              io.Writer
	controlSequence io.Writer

	// inputHook is called whenever an input is received
	inputHook func()

	closeChan chan bool
	client    *dockerclient.Client
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
	s.in.Write([]byte(data))
}

// ControlSequence is called when a non-printable key is pressed on the terminal.
func (s *Server) ControlSequence(d *dnode.Partial) {
	data := d.MustSliceOfLength(1)[0].MustString()
	s.controlSequence.Write([]byte(data))
}

func (s *Server) SetSize(d *dnode.Partial) {
	args := d.MustSliceOfLength(2)
	x := args[0].MustFloat64()
	y := args[1].MustFloat64()

	err := s.client.ResizeExecTTY(s.Session, int(y), int(x))
	if err != nil {
		fmt.Println("error resizing", err)
	}
}

func (s *Server) Close(d *dnode.Partial) {
	select {
	case <-s.closeChan:
	default:
		close(s.closeChan)
	}
}

func (s *Server) Terminate(d *dnode.Partial) {
	s.Close(d)
}
