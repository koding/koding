package proxy

import (
    "os/user"
    "sync"

    "github.com/koding/kite"
)

// User represents the Koding user that is making requests.
type User struct {
    sessions    map[string]*Exec
    sync.Mutex
}

// AddSession adds the Exec instance to the requesting
// User's map of sessions with the provided id.
func (u *User) AddSession(id string, e *Exec) {
    u.Lock()
    defer u.Unlock()

    u.sessions[id] = e
}

func (u *User) TerminateSession(id string) {
    u.Lock()
    defer u.Unlock()

    e, ok := u.sessions[id]
    if !ok {
        return
    }

    // Tell the Exec instance to terminate.
    e.Terminate(nil)
}

// Session returns the corresponding *Exec instance when the specified
// session id exists.
func (u *User) Session(id string) *Exec {
    u.Lock()
    defer u.Unlock()

    return u.sessions[id]
}

// Sessions returns a slice of session ids that the specified user
// currently has open.
func (u *User) Sessions() []string {
    u.Lock()
    defer u.Unlock()

    keys := make([]string, len(u.sessions))

    for k, _ := range u.sessions {
        keys = append(keys, k)
    }

    return keys
}

type Singleton struct {
    users       map[string]*User
    sync.Mutex
}

func (s *Singleton) User(id string) *User {
    s.Lock()
    defer s.Unlock()

    if _, ok := s.users[id]; !ok {
        s.users[id] = &User{
            sessions: make(map[string]*Exec),
        }
    }

    return s.users[id]
}

func (s *Singleton) DeleteUser(id string) {
    s.Lock()
    defer s.Unlock()

    if _, ok := s.users[id]; !ok {
        return
    }

    delete(s.users, id)
}

var singleton *Singleton
var once sync.Once

func instance() *Singleton {
    once.Do(func () {
        singleton = &Singleton{
            users:  make(map[string]*User),
        }
    })

    return singleton
}

// Implement the terminal.Terminal interface
func (p *KubernetesProxy) GetSessions(r *kite.Request) (interface{}, error) {
    user, err := user.Current()
	if err != nil {
		return nil, err
	}

    store := instance().User(user.Username)

    return store.Sessions(), nil
}

// Implement the terminal.Terminal interface
func (p *KubernetesProxy) Connect(r *kite.Request) (interface{}, error) {
    user, err := user.Current()
    if err != nil {
        return nil, err
    }

    store := instance().User(user.Username)

    // TODO (acbodine): exec'ing to K8s api is different from how the
    // existing terminal implementation carries on a TTY session. For
    // now, leave it up to the requesting kite to provide different
    // parameters based on the status of `klient.info`. The client behavior
    // will likely be different anyway.
    resp, err := p.Exec(r)
    if err != nil {
        return nil, err
    }

    e, _ := resp.(*Exec)

    store.AddSession(e.Session, e)

    return resp, err
}

// Implement the terminal.Terminal interface
func (p *KubernetesProxy) KillSession(r *kite.Request) (interface{}, error) {
    var params struct {
        Session     string
    }

    if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

    user, err := user.Current()
    if err != nil {
        return nil, err
    }

    store := instance().User(user.Username)

    store.TerminateSession(params.Session)

    return true, nil
}

// Implement the terminal.Terminal interface
func (p *KubernetesProxy) KillSessions(r *kite.Request) (interface{}, error) {
    user, err := user.Current()
    if err != nil {
        return nil, err
    }

    store := instance().User(user.Username)

    for _, id := range store.Sessions() {
        store.TerminateSession(id)
    }

    return true, nil
}

// Implement the terminal.Terminal interface
func (p *KubernetesProxy) RenameSession(r *kite.Request) (interface{}, error) {

    // TODO (acbodine): do we need this?
    return true, nil
}

// Implement the terminal.Terminal interface
func (p *KubernetesProxy) CloseSessions(username string) {
    store := instance().User(username)

    for _, id := range store.Sessions() {
        store.TerminateSession(id)
    }

    instance().DeleteUser(username)
}
