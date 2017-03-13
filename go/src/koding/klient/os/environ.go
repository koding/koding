package os

import (
	"errors"
	"fmt"
	"sort"
	"strings"
)

// Environ is a convenience wrapper for environment variables
// produced by os.Environ.
type Environ map[string]string

func (e Environ) Encode(m Environ) []string {
	envs := make([]string, 0, len(e))

	for key, val := range m {
		envs = append(envs, key+"="+val)
	}

	for key, val := range e {
		if _, ok := m[key]; ok {
			continue
		}
		envs = append(envs, key+"="+val)
	}

	sort.Strings(envs)

	return envs
}

// Match tells whether variables in m matches the ones in e.
func (e Environ) Match(m Environ) error {
	for key, val := range m {
		v, ok := e[key]
		if !ok {
			return errors.New("env does not exist: " + key)
		}

		if v != val {
			return fmt.Errorf("env value mismatch: %s: %q != %q", key, val, v)
		}
	}

	return nil
}

// String encodes variables to a textual representation,
// suitable to e.g. pass them via command line.
func (e Environ) String() string {
	return strings.Join(e.Encode(nil), ",")
}

// NewEnviron creates new variable map out of variable slice.
func NewEnviron(envs []string) Environ {
	e := make(Environ)

	for _, env := range envs {
		if env == "" {
			continue
		}

		if i := strings.IndexRune(env, '='); i != -1 {
			e[env[:i]] = env[i+1:]
		} else {
			e[env] = ""
		}
	}

	return e
}

// ParseEnviron parses textual representation of variable list
// to a environment variable map.
func ParseEnviron(env string) Environ {
	return NewEnviron(strings.Split(env, ","))
}
