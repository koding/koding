package pty

import (
	"io"
	"os"
)

type PTY struct {
	Master        *os.File
	MasterEncoded io.WriteCloser
	No            int
	Slave         *os.File
}

const DefaultPtsPath = "/dev/pts"

func New(ptsPath string) *PTY {
	panic("PTY not supported on OSX")
	return nil
}

func (pty *PTY) SetSize(x, y uint16) {
}
