// +build darwin
// mountcli is a little package for interacting with the local "mount" command
package mountcli

import (
	"fmt"
	"os/exec"
	"strings"
)

// An OS specific mount tag that we're filtering by.
const defaultFuseTag = "osxfusefs"

type Mount struct {
	// The name of the binary we'll be running and parsing. Should almost always
	// be "mount"
	binName string

	// the following vars exist primarily for mocking ability, and ensuring
	// an enclosed environment within the struct.

	// A func to run the given binary and return the output as a string
	binRunner func(string) (string, error)
}

// NewMount creates a new Mount instance.
func NewMount() *Mount {
	return &Mount{
		binName:   "mount",
		binRunner: binRunner,
	}
}

// FindMountedPathByName returns the systems mounted path for the given name.
func (m *Mount) FindMountedPathByName(name string) (string, error) {
	out, err := m.binRunner(m.binName)
	if err != nil {
		return "", err
	}

	prefix := fmt.Sprintf("%s on ", name)
	lines := strings.Split(out, "\n")
	for _, line := range lines {
		if !strings.HasPrefix(line, prefix) {
			continue
		}

		line = line[len(prefix):]
		index := strings.LastIndex(line, fmt.Sprintf(" ("))
		if index == -1 {
			continue
		}

		return line[:index], nil
	}

	return "", nil
}

func binRunner(bin string) (string, error) {
	cmd := exec.Command(bin, "-t", defaultFuseTag)

	out, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}

	return string(out), nil
}
