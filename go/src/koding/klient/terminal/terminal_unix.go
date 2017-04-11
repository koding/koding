// +build !windows

// Package terminal provides a tty emulation and session handlings that is
// supported via Screen
package terminal

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"sync"
	"syscall"
	"time"
	"unicode/utf8"

	"koding/kites/config"
	"koding/klient/terminal/pty"

	"github.com/koding/kite"
)

type terminal struct {
	InputHook    func()
	Log          kite.Logger
	screenrcPath string

	Users      map[string]*User
	sync.Mutex // protects Users
}

func newTerminal(log kite.Logger, screenPath string, hook func()) Terminal {
	return &terminal{
		Users:        make(map[string]*User),
		screenrcPath: screenPath,
		Log:          log,
		InputHook:    hook,
	}
}

func (t *terminal) HasLimit(username string) bool {
	t.Lock()
	defer t.Unlock()

	user, ok := t.Users[username]
	if !ok {
		// not available yet so it's good to go
		return false
	}

	return user.HasLimit()
}

// AddUserSession adds the given username and session
func (t *terminal) AddUserSession(username, session string, server *Server) {
	t.Lock()
	defer t.Unlock()

	// check if it's exists, if not go and lazy initialize a new user instance
	var user *User
	var ok bool
	user, ok = t.Users[username]
	if !ok {
		user = NewUser(username)
	}

	user.AddSession(session, server)
	t.Users[username] = user
}

// DeleteUserSession deletes the given session from the Users map
func (t *terminal) DeleteUserSession(username, session string) {
	t.Lock()
	defer t.Unlock()

	user, ok := t.Users[username]
	if !ok {
		return // nothing to do
	}

	user.DeleteSession(session)

	if len(user.Sessions) == 0 {
		delete(t.Users, username)
	}
}

// RenameUserSession renames the given users session in the Users map
func (t *terminal) RenameUserSession(username, oldName, newName string) error {
	t.Lock()
	defer t.Unlock()

	user, ok := t.Users[username]
	if !ok {
		return errors.New("username not available")
	}

	user.RenameSession(oldName, newName)
	t.Users[username] = user

	return nil
}

// KillSession kills the given screen session
func (t *terminal) KillSession(r *kite.Request) (interface{}, error) {
	var params struct {
		Session string
	}

	if r.Args.One().Unmarshal(&params) != nil {
		return nil, errors.New("{ session: [string] }")
	}

	if params.Session == "" {
		return nil, errors.New("session is empty")
	}

	if err := t.killSession(params.Session); err != nil {
		return nil, err
	}

	t.DeleteUserSession(r.Username, params.Session)

	return true, nil
}

// KillSessions kills all available screen sessions
func (t *terminal) KillSessions(r *kite.Request) (interface{}, error) {
	user, err := user.Current()
	if err != nil {
		return nil, fmt.Errorf("Could not get user: %s", err)
	}

	if err := t.killSessions(user.Username); err != nil {
		return nil, err
	}

	return true, nil
}

// RenameSession renames the given session to the new session name
func (t *terminal) RenameSession(r *kite.Request) (interface{}, error) {
	var params struct {
		OldName string `json:"oldName"`
		NewName string `json:"newName"`
	}

	if r.Args.One().Unmarshal(&params) != nil {
		return nil, errors.New("{ oldName: [string] newName: [string] }")
	}

	if params.OldName == "" {
		return nil, errors.New("session name empty")
	}

	if params.NewName == "" {
		return nil, errors.New("session name to be renamed is empty")
	}

	// prevent to rename it to a session that exists already
	if t.sessionExists(params.NewName, r.Username) {
		return nil, ErrNoSession
	}

	if err := t.renameSession(params.OldName, params.NewName); err != nil {
		return nil, err
	}

	t.RenameUserSession(r.Username, params.OldName, params.NewName)

	return true, nil
}

// GetSessions return a list of curren active screen sessions
func (t *terminal) GetSessions(r *kite.Request) (interface{}, error) {
	user, err := user.Current()
	if err != nil {
		return nil, fmt.Errorf("Could not get user: %s", err)
	}

	sessions := t.screenSessions(user.Username)
	if len(sessions) == 0 {
		return nil, errors.New("no sessions available")
	}

	return sessions, nil
}

// Connect creates and open a new TTY instance. It returns a *Server instance
// so every caller can send and receive from the connected TTY end.
func (t *terminal) Connect(r *kite.Request) (interface{}, error) {
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

	if params.Mode == "create" && t.HasLimit(r.Username) {
		return nil, errors.New("session limit has reached")
	}

	command, err := t.newCommand(params.Mode, params.Session, config.CurrentUser.Username)
	if err != nil {
		t.Log.Warning("terminal: connect failed for user %q: %s", config.CurrentUser.Username, err)

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

	t.AddUserSession(r.Username, command.Session, server)

	// wrap the command with sudo -i for initiation login shell. This is needed
	// in order to have Environments and other to be initialized correctly.
	// check also if klient was started in root mode or not.
	var args []string
	if os.Geteuid() == 0 {
		args = []string{"-i", command.Name}
	} else {
		args = []string{"-i", "-u", config.CurrentUser.Username, "--", command.Name}
	}

	// check if we have custom screenrc path and there is a file for it. If yes
	// use it for screen binary otherwise it'll just start without any screenrc.
	if t.screenrcPath != "" {
		if _, err := os.Stat(t.screenrcPath); err == nil {
			args = append(args, "-c", t.screenrcPath)
		}
	}

	args = append(args, command.Args...)
	var cmd *exec.Cmd

	if _, err := os.Stat("/usr/bin/sudo"); os.IsNotExist(err) {
		cmd = exec.Command(args[1], args[2:]...)
	} else {
		cmd = exec.Command("/usr/bin/sudo", args...)
	}

	// For test use this, sudo is not going to work
	// cmd := exec.Command(command.Name, command.Args...)

	var stderr bytes.Buffer

	cmd.Env = screenEnv
	cmd.Stdin = server.pty.Slave
	cmd.Stdout = server.pty.Slave
	cmd.Dir = config.CurrentUser.HomeDir
	cmd.Stderr = &stderr

	// Open in background, this is needed otherwise the process will be killed
	// if you hit close on the client side.
	cmd.SysProcAttr = &syscall.SysProcAttr{Setctty: true, Setsid: true}

	t.Log.Debug("terminal: starting session %q: %v (%v)", command.Session, cmd.Args, screenEnv)

	err = cmd.Start()
	if err != nil {
		t.Log.Error("terminal: could not start session %q: %s", command.Session, err)
	}

	// Wait until the shell process is closed and notify the client.
	go func() {
		err := cmd.Wait()
		if err != nil {
			t.Log.Error("terminal: session %q wait error: %s: %s\n", command.Session, err, &stderr)
		} else {
			t.Log.Debug("terminal: session %q has ended: %s", command.Session, &stderr)
		}

		server.pty.Slave.Close()
		server.pty.Master.Close()
		server.remote.SessionEnded.Call()

		t.DeleteUserSession(r.Username, command.Session)
	}()

	// Read the STDOUT from shell process and send to the connected client.
	go func() {
		buf := make([]byte, (4096)-utf8.UTFMax, 4096)
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

// CloseSessions closes all active session for the given username and deletes
// it from the internal user map
func (t *terminal) CloseSessions(username string) {
	t.Log.Info("Closing terminal sessions of user '%s'", username)

	t.Lock()
	user, ok := t.Users[username]
	t.Unlock()

	if !ok {
		return
	}

	user.CloseSessions()

	t.Lock()
	delete(t.Users, username)
	t.Unlock()
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
