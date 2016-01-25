package util

import "strings"

// GetEnvByKey parses through the given Environ formatted slice and returns the
// value of the given key if it exists.
func GetEnvByKey(envs []string, key string) string {
	for _, s := range envs {
		env := strings.Split(s, "=")

		if len(env) != 2 {
			continue
		}

		if env[0] == key {
			return env[1]
		}
	}

	return ""
}
