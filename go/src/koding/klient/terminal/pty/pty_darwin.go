package pty

import (
	"errors"
	"fmt"
	"io"
	"os"
	"syscall"
	"unsafe"

	"github.com/rogpeppe/go-charset/charset"
	_ "github.com/rogpeppe/go-charset/data"
)

type PTY struct {
	Master        *os.File
	MasterEncoded io.WriteCloser
	No            int
	Slave         *os.File
}

// see ioccom.h
const sys_IOCPARM_MASK = 0x1fff

func NewPTY() (*PTY, error) {
	return New("")
}

func New(ptsPath string) (*PTY, error) {
	pty, err := os.OpenFile("/dev/ptmx", os.O_RDWR, 0)
	if err != nil {
		return nil, fmt.Errorf("open pty %s", err)
	}

	sname, err := ptsname(pty)
	if err != nil {
		return nil, fmt.Errorf("ptsname %s", err)
	}

	err = grantpt(pty)
	if err != nil {
		return nil, fmt.Errorf("grantpt %s", err)
	}

	err = unlockpt(pty)
	if err != nil {
		return nil, fmt.Errorf("unlockpt %s", err)
	}

	tty, err := os.OpenFile(sname, os.O_RDWR, 0)
	if err != nil {
		return nil, fmt.Errorf("open tty %s", err)
	}

	masterEncoded, err := charset.NewWriter("ISO-8859-1", pty)
	if err != nil {
		return nil, fmt.Errorf("charset %s", err)
	}

	return &PTY{
		Master:        pty,
		Slave:         tty,
		No:            0,
		MasterEncoded: masterEncoded,
	}, nil
}

func (pty *PTY) GetSize() (int, int, error) {
	var ws winsize
	err := windowrect(&ws, pty.Master.Fd())
	return int(ws.ws_row), int(ws.ws_col), err
}

func (pty *PTY) SetSize(x, y uint16) {
	winsize := winsize{ws_col: x, ws_row: y}
	err := windowrect(&winsize, pty.Master.Fd())
	if err != nil {
		fmt.Println("error setting windows size", err)
	}
}

func (pty *PTY) Signal(sig syscall.Signal) {
	// TODO: implement this
}

type winsize struct {
	ws_row    uint16
	ws_col    uint16
	ws_xpixel uint16
	ws_ypixel uint16
}

func windowrect(ws *winsize, fd uintptr) error {
	_, _, errno := syscall.Syscall(
		syscall.SYS_IOCTL,
		fd,
		syscall.TIOCSWINSZ,
		uintptr(unsafe.Pointer(ws)),
	)
	if errno != 0 {
		return syscall.Errno(errno)
	}
	return nil
}

func ptsname(f *os.File) (string, error) {
	var n [(syscall.TIOCPTYGNAME >> 16) & sys_IOCPARM_MASK]byte

	ioctl(f.Fd(), syscall.TIOCPTYGNAME, uintptr(unsafe.Pointer(&n)))
	for i, c := range n {
		if c == 0 {
			return string(n[:i]), nil
		}
	}
	return "", errors.New("TIOCPTYGNAME string not NUL-terminated")
}

func grantpt(f *os.File) error {
	var u int
	return ioctl(f.Fd(), syscall.TIOCPTYGRANT, uintptr(unsafe.Pointer(&u)))
}

func unlockpt(f *os.File) error {
	var u int
	return ioctl(f.Fd(), syscall.TIOCPTYUNLK, uintptr(unsafe.Pointer(&u)))
}

func ioctl(fd, cmd, ptr uintptr) error {
	_, _, e := syscall.Syscall(syscall.SYS_IOCTL, fd, cmd, ptr)
	if e != 0 {
		return syscall.ENOTTY
	}
	return nil
}
