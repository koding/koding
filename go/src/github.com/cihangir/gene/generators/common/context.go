package common

import "github.com/cihangir/gene/config"

// Context holds contextual information for ongoing operations.
type Context struct {
	Config *config.Config
}

// NewContext creates a new context with sane defaults.
func NewContext() *Context {
	return &Context{
		Config: &config.Config{
			Target: "./",
			Generators: []string{
				"ddl", "rows", "kit", "errors",
				"dockerfiles", "clients", "tests",
				"functions", "models", "js",
				// "tests-funcs", "tests",
			},
		},
	}
}
