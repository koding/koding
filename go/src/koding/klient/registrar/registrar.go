package registrar

import (
    "sync"
)

var r *Registry = &Registry{}

type Registry struct {
    methods []string
    sync.Mutex
}

func Register(name string) {
    r.Lock()
    defer r.Unlock()

    r.methods = append(r.methods, name)
}

func Methods() []string {
    return r.methods
}
