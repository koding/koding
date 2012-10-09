package pty

import (
	"code.google.com/p/go-charset/charset"
	_ "code.google.com/p/go-charset/data"
	"io"
	"os"
	"os/exec"
	"syscall"
	"unsafe"
)

/*
#ifdef __APPLE__
#  include <util.h>
#else
#  include <pty.h>
#endif
#cgo LDFLAGS: -lutil
*/
import "C"

type PTY struct {
	Master        *os.File
	MasterEncoded io.WriteCloser
	Slave         *os.File
}

func New() *PTY {
	var master, slave C.int
	C.openpty(&master, &slave, nil, nil, nil)
	masterFile := os.NewFile(uintptr(master), "")
	slaveFile := os.NewFile(uintptr(slave), "")
	encodedMaster, err := charset.NewWriter("ISO-8859-1", masterFile)
	if err != nil {
		panic(err)
	}
	return &PTY{masterFile, encodedMaster, slaveFile}
}

func (pty *PTY) AdaptCommand(cmd *exec.Cmd) {
	pty.Slave.Chown(int(cmd.SysProcAttr.Credential.Uid), -1)
	cmd.Stdin = pty.Slave
	cmd.Stdout = pty.Slave
	cmd.Stderr = pty.Slave
	cmd.SysProcAttr.Setsid = true
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
