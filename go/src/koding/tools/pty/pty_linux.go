package pty

import (
	"fmt"
	"io"
	"os"
	"strconv"
	"syscall"
	"unsafe"

	"github.com/kr/pty"
	"github.com/rogpeppe/go-charset/charset"
	_ "github.com/rogpeppe/go-charset/data"
)

type PTY struct {
	Master        *os.File
	MasterEncoded io.WriteCloser
	No            int
	Slave         *os.File
}

const DefaultPtsPath = "/dev/pts"

// NewPTY() is a newer version base on pty package, this opens from /dev/ptmx
// and find the slave tty from the /dev/pts folder automatically
func NewPTY() (*PTY, error) {
	pty, tty, err := pty.Open()
	if err != nil {
		return nil, err
	}

	masterEncoded, err := charset.NewWriter("ISO-8859-1", pty)
	if err != nil {
		return nil, err
	}

	return &PTY{
		Master:        pty,
		Slave:         tty,
		No:            0,
		MasterEncoded: masterEncoded,
	}, nil
}

func New(ptsPath string) (*PTY, error) {
	// open master
	master, err := os.OpenFile(ptsPath+"/ptmx", os.O_RDWR, 0)
	if err != nil {
		return nil, fmt.Errorf("open pty %s", err)
	}

	pty := &PTY{Master: master}

	// unlock slave
	var unlock int32
	if err := pty.Ioctl(syscall.TIOCSPTLCK, uintptr(unsafe.Pointer(&unlock))); err != nil {
		return nil, fmt.Errorf("failed to unlock pty %s", err)
	}

	// find out slave name
	var ptyno uint32
	if err := pty.Ioctl(syscall.TIOCGPTN, uintptr(unsafe.Pointer(&ptyno))); err != nil {
		return nil, fmt.Errorf("failed to get ptyno %s", err)
	}
	pty.No = int(ptyno)

	// open slave
	slave, err := os.OpenFile(ptsPath+"/"+strconv.Itoa(pty.No), os.O_RDWR|syscall.O_NOCTTY, 0)
	if err != nil {
		return nil, fmt.Errorf("open tty %s", err)
	}
	pty.Slave = slave

	// apply proper encoding
	masterEncoded, err := charset.NewWriter("ISO-8859-1", master)
	if err != nil {
		return nil, fmt.Errorf("charset %s", err)
	}
	pty.MasterEncoded = masterEncoded

	return pty, nil
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
		return
	}
	process, err := os.FindProcess(pgid)
	if err != nil {
		return
	}
	if err := process.Signal(sig); err != nil {
		return
	}
}
