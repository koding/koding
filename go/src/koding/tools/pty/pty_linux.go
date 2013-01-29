package pty

import (
	"code.google.com/p/go-charset/charset"
	_ "code.google.com/p/go-charset/data"
	"io"
	"os"
	"strconv"
	"syscall"
	"unsafe"
)

type PTY struct {
	Master        *os.File
	MasterEncoded io.WriteCloser
	No            int
	Slave         *os.File
}

const DefaultPtsPath = "/dev/pts"

func New(ptsPath string) *PTY {
	// open master
	master, err := os.OpenFile(ptsPath+"/ptmx", os.O_RDWR, 0)
	if err != nil {
		panic(err)
	}

	// unlock slave
	var unlock int32
	_, _, errno := syscall.Syscall(syscall.SYS_IOCTL, master.Fd(), syscall.TIOCSPTLCK, uintptr(unsafe.Pointer(&unlock)))
	if errno != 0 {
		panic("Failed to unlock pty")
	}

	// find out slave name
	var ptyno uint32
	_, _, errno = syscall.Syscall(syscall.SYS_IOCTL, master.Fd(), syscall.TIOCGPTN, uintptr(unsafe.Pointer(&ptyno)))
	if errno != 0 {
		panic("Failed to get ptyno")
	}

	// open slave
	slave, err := os.OpenFile(ptsPath+"/"+strconv.Itoa(int(ptyno)), os.O_RDWR|syscall.O_NOCTTY, 0)
	if err != nil {
		panic(err)
	}

	// apply proper encoding
	encodedMaster, err := charset.NewWriter("ISO-8859-1", master)
	if err != nil {
		panic(err)
	}

	return &PTY{master, encodedMaster, int(ptyno), slave}
}

type winsize struct {
	ws_row, ws_col, ws_xpixel, ws_ypixel uint16
}

func (pty *PTY) SetSize(x, y uint16) {
	winsize := winsize{ws_col: x, ws_row: y}
	syscall.Syscall(syscall.SYS_IOCTL, pty.Slave.Fd(), syscall.TIOCSWINSZ, uintptr(unsafe.Pointer(&winsize)))
}
