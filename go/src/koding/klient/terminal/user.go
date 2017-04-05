// +build !windows

package terminal

import (
	"errors"
	"sync"
)

type User struct {
	username   string
	Sessions   map[string]*Server
	sync.Mutex // protects sessions

	//ScreenSessionLimit defines the maximum number of sessions a user can
	//create, it's useful to avoid spamming the remote host.
	ScreenSessionLimit int
}

func NewUser(username string) *User {
	return &User{
		username:           username,
		Sessions:           make(map[string]*Server),
		ScreenSessionLimit: 20,
	}
}

func (u *User) AddSession(session string, server *Server) {
	u.Lock()
	defer u.Unlock()

	u.Sessions[session] = server
}

// HasLimit checks whether the session. It returns true if the limit has been
// reached
func (u *User) HasLimit() bool {
	u.Lock()
	defer u.Unlock()

	return len(u.Sessions) == u.ScreenSessionLimit
}

func (u *User) Session(session string) (*Server, bool) {
	u.Lock()
	defer u.Unlock()

	server, ok := u.Sessions[session]
	return server, ok
}

func (u *User) DeleteSession(session string) {
	u.Lock()
	defer u.Unlock()

	delete(u.Sessions, session)
}

func (u *User) RenameSession(oldName, newName string) error {
	u.Lock()
	defer u.Unlock()

	server, ok := u.Sessions[oldName]
	if !ok {
		return errors.New("session not available")
	}

	// check so we don't override already existing session
	_, ok = u.Sessions[newName]
	if !ok {
		return errors.New("new session exists already")
	}

	delete(u.Sessions, oldName)
	u.Sessions[newName] = server

	return nil
}

// CloseSessions close the users all active sessions
func (u *User) CloseSessions() {
	u.Lock()
	defer u.Unlock()

	for _, session := range u.Sessions {
		session.Close(nil)

		session.remote.SessionEnded.Call()
		session.pty.Slave.Close()
		session.pty.Master.Close()
	}
}
