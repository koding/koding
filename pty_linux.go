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

	pty := &PTY{Master: master}

	// unlock slave
	var unlock int32
	if err := pty.Ioctl(syscall.TIOCSPTLCK, uintptr(unsafe.Pointer(&unlock))); err != nil {
		panic("Failed to unlock pty")
	}

	// find out slave name
	var ptyno uint32
	if err := pty.Ioctl(syscall.TIOCGPTN, uintptr(unsafe.Pointer(&ptyno))); err != nil {
		panic("Failed to get ptyno")
	}
	pty.No = int(ptyno)

	// open slave
	slave, err := os.OpenFile(ptsPath+"/"+strconv.Itoa(pty.No), os.O_RDWR|syscall.O_NOCTTY, 0)
	if err != nil {
		panic(err)
	}
	pty.Slave = slave

	// apply proper encoding
	masterEncoded, err := charset.NewWriter("ISO-8859-1", master)
	if err != nil {
		panic(err)
	}
	pty.MasterEncoded = masterEncoded

	return pty
}

func (pty *PTY) Ioctl(a2, a3 uintptr) error {
	if _, _, errno := syscall.Syscall(syscall.SYS_IOCTL, pty.Master.Fd(), a2, a3); errno != 0 {
		return errno
	}
	return nil
}

type winsize struct {
	ws_row, ws_col, ws_xpixel, ws_ypixel uint16
}

func (pty *PTY) SetSize(x, y uint16) {
	winsize := winsize{ws_col: x, ws_row: y}
	if err := pty.Ioctl(syscall.TIOCSWINSZ, uintptr(unsafe.Pointer(&winsize))); err != nil {
		panic(err)
	}
}

func (pty *PTY) Signal(sig syscall.Signal) {
	var pgid int
	if err := pty.Ioctl(syscall.TIOCGPGRP, uintptr(unsafe.Pointer(&pgid))); err != nil {
		panic("Failed to get process group")
	}
	process, err := os.FindProcess(pgid)
	if err != nil {
		panic(err)
	}
	if err := process.Signal(sig); err != nil {
		panic("Failed to send signal")
	}
}
