package pty

import (
	"code.google.com/p/go-charset/charset"
	_ "code.google.com/p/go-charset/data"
	"io"
	"os"
	"syscall"
	"unsafe"
)

/*
#include <pty.h>
#cgo LDFLAGS: -lutil
*/
import "C"

type PTY struct {
	Master        *os.File
	MasterEncoded io.WriteCloser
	Slave         *os.File
}

func New(uid int) *PTY {
	var master, slave C.int
	C.openpty(&master, &slave, nil, nil, nil)
	masterFile := os.NewFile(uintptr(master), "")
	slaveFile := os.NewFile(uintptr(slave), "")
	slaveFile.Chown(uid, -1)
	encodedMaster, err := charset.NewWriter("ISO-8859-1", masterFile)
	if err != nil {
		panic(err)
	}
	return &PTY{masterFile, encodedMaster, slaveFile}
}

func (pty *PTY) StartProcess(command []string, procAttr *os.ProcAttr) (*os.Process, error) {
	if procAttr == nil {
		procAttr = new(os.ProcAttr)
	}
	procAttr.Files = []*os.File{pty.Slave, pty.Slave, pty.Slave}
	return os.StartProcess(command[0], command, procAttr)
}

type winsize struct {
	ws_row, ws_col, ws_xpixel, ws_ypixel C.ushort
}

func (pty *PTY) SetSize(x, y uint16) {
	winsize := winsize{
		ws_col: C.ushort(x),
		ws_row: C.ushort(y),
	}
	syscall.Syscall(syscall.SYS_IOCTL, pty.Slave.Fd(), syscall.TIOCSWINSZ, uintptr(unsafe.Pointer(&winsize)))
}
