package terminal

import "sync"

type User struct {
	username   string
	Sessions   map[string]*Server
	sync.Mutex // protects sessions
}

func NewUser(username string) *User {
	return &User{
		username: username,
		Sessions: make(map[string]*Server),
	}
}

func (u *User) AddSession(session string, server *Server) {
	u.Lock()
	defer u.Unlock()

	u.Sessions[session] = server
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
