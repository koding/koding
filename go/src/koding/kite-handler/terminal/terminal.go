// Package terminal provides a tty emulation and session handlings that is
// supported via Screen
package terminal

import (
	"bytes"
	"errors"
	"fmt"
	"koding/tools/pty"
	"os"
	"os/exec"
	"os/user"
	"syscall"
	"time"
	"unicode/utf8"

	"github.com/koding/kite"
)

type Terminal struct {
	InputHook func()
}

func (t *Terminal) KillSession(r *kite.Request) (interface{}, error) {
	var params struct {
		Session string
	}

	if r.Args.One().Unmarshal(&params) != nil {
		return nil, errors.New("{ session: [string] }")
	}

	if params.Session == "" {
		return nil, errors.New("session is empty")
	}

	if err := killSession(params.Session); err != nil {
		return nil, err
	}

	return true, nil
}

func (t *Terminal) GetSessions(r *kite.Request) (interface{}, error) {
	user, err := user.Current()
	if err != nil {
		return nil, fmt.Errorf("Could not get home dir: %s", err)
	}

	sessions := screenSessions(user.Username)
	if len(sessions) == 0 {
		return nil, errors.New("no sessions available")
	}

	return sessions, nil
}

func (t *Terminal) Connect(r *kite.Request) (interface{}, error) {
	var params struct {
		Remote       Remote
		Session      string
		SizeX, SizeY int
		Mode         string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, fmt.Errorf("{ remote: [object], session: %s, noScreen: [bool] }, err: %s",
			params.Session, err)
	}

	if params.SizeX <= 0 || params.SizeY <= 0 {
		return nil, fmt.Errorf("{ sizeX: %d, sizeY: %d } { raw JSON : %v }", params.SizeX, params.SizeY, r.Args.One())
	}

	user, err := user.Current()
	if err != nil {
		return nil, fmt.Errorf("Could not get home dir: %s", err)
	}

	command, err := newCommand(params.Mode, params.Session, user.Username)
	if err != nil {
		return nil, err
	}

	// get pty and tty descriptors
	p, err := pty.NewPTY()
	if err != nil {
		return nil, err
	}

	// We will return this object to the client.
	server := &Server{
		Session:   command.Session,
		remote:    params.Remote,
		pty:       p,
		inputHook: t.InputHook,
	}
	server.setSize(float64(params.SizeX), float64(params.SizeY))

	// wrap the command with sudo -i for initiation login shell. This is needed
	// in order to have Environments and other to be initialized correctly.
	// check also if klient was started in root mode or not.
	var args []string
	if os.Geteuid() == 0 {
		args = []string{"-i", command.Name}
	} else {
		args = []string{"-i", "-u", "#" + user.Uid, "--", command.Name}
	}

	args = append(args, command.Args...)
	cmd := exec.Command("/usr/bin/sudo", args...)

	// For test use this, sudo is not going to work
	// cmd := exec.Command(command.Name, command.Args...)

	cmd.Env = []string{"TERM=xterm-256color", "HOME=" + user.HomeDir}
	cmd.Stdin = server.pty.Slave
	cmd.Stdout = server.pty.Slave
	cmd.Dir = user.HomeDir
	// cmd.Stderr = server.pty.Slave

	// Open in background, this is needed otherwise the process will be killed
	// if you hit close on the client side.
	cmd.SysProcAttr = &syscall.SysProcAttr{Setctty: true, Setsid: true}
	err = cmd.Start()
	if err != nil {
		fmt.Println("could not start", err)
	}

	// Wait until the shell process is closed and notify the client.
	go func() {
		err := cmd.Wait()
		if err != nil {
			fmt.Println("cmd.wait err", err)
		}

		server.pty.Slave.Close()
		server.pty.Master.Close()
		server.remote.SessionEnded.Call()
	}()

	// Read the STDOUT from shell process and send to the connected client.
	go func() {
		buf := make([]byte, (1<<12)-utf8.UTFMax, 1<<12)
		for {
			n, err := server.pty.Master.Read(buf)
			for n < cap(buf)-1 {
				r, _ := utf8.DecodeLastRune(buf[:n])
				if r != utf8.RuneError {
					break
				}
				server.pty.Master.Read(buf[n : n+1])
				n++
			}

			// Rate limiting...
			if server.throttling {
				s := time.Now().Unix()
				if server.currentSecond != s {
					server.currentSecond = s
					server.messageCounter = 0
					server.byteCounter = 0
					server.lineFeeedCounter = 0
				}
				server.messageCounter += 1
				server.byteCounter += n
				server.lineFeeedCounter += bytes.Count(buf[:n], []byte{'\n'})
				if server.messageCounter > 100 || server.byteCounter > 1<<18 || server.lineFeeedCounter > 300 {
					time.Sleep(time.Second)
				}
			}

			server.remote.Output.Call(string(filterInvalidUTF8(buf[:n])))
			if err != nil {
				break
			}
		}
	}()

	return server, nil
}

func filterInvalidUTF8(buf []byte) []byte {
	i := 0
	j := 0
	for {
		r, l := utf8.DecodeRune(buf[i:])
		if l == 0 {
			break
		}
		if r < 0xD800 {
			if i != j {
				copy(buf[j:], buf[i:i+l])
			}
			j += l
		}
		i += l
	}
	return buf[:j]
}
