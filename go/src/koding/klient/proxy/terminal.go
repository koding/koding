package proxy

import (
    "sync"

    "github.com/koding/kite"
)

type User struct {
    sessions    map[string]*Exec
    sync.Mutex
}

func (u *User) AddSession(id string, e *Exec) {
    u.Lock()
    defer u.Unlock()

    u.sessions[id] = e
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
    user := instance().User(r.Username)

    return user.Sessions(), nil
}

// Implement the terminal.Terminal interface
func (p *KubernetesProxy) Connect(r *kite.Request) (interface{}, error) {
    user := instance().User(r.Username)

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

    user.AddSession(e.Session, e)

    return resp, err
}

// Implement the terminal.Terminal interface
func (p *KubernetesProxy) KillSession(r *kite.Request) (interface{}, error) {
    return nil, nil
}

// Implement the terminal.Terminal interface
func (p *KubernetesProxy) KillSessions(r *kite.Request) (interface{}, error) {
    return nil, nil
}

// Implement the terminal.Terminal interface
func (p *KubernetesProxy) RenameSession(r *kite.Request) (interface{}, error) {
    return nil, nil
}

// Implement the terminal.Terminal interface
func (p *KubernetesProxy) CloseSessions(string) {
    return
}
