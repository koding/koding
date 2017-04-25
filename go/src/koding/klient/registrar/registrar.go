package registrar

var registry *Registry = &Registry{}

type Registry struct {
    methods []string
}

func Register(name string) {
    registry.methods = append(registry.methods, name)
}

func Methods() []string {
    return registry.methods
}
