// +build darwin
// mountcli is a little package for interacting with the local "mount" command.
//
// A typical osxfusefs mount entry looks like:
//  mount_name1 on /path/to/mount1 (osxfusefs, nodev, nosuid, synchronous, mounted by user1)
package mountcli

import (
	"errors"
	"fmt"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

// An OS specific mount tag that we're filtering by.
const defaultFuseTag = "osxfusefs"

var (
	// ErrNotInMount happens when command is run from outside a mount.
	ErrNotInMount = errors.New("command not run on mount")

	// ErrNoMountName happens when no mount with given name.
	ErrNoMountName = errors.New("No mount found with given name.")

	// ErrNoMountName happens when no mount there's mount on given path.
	ErrNoMountPath = errors.New("No mount found with given path.")

	// folderSeparator is the os specific seperator for dividing folders.
	folderSeparator = string(filepath.Separator)

	// match from beginning to ' on '
	nameMatch = regexp.MustCompile(fmt.Sprintf("^(.*?) on "))

	// match from ' on ' till '(osxfusefs,'
	pathMatch = regexp.MustCompile(
		fmt.Sprintf(" on (.*?) \\(%s,", defaultFuseTag),
	)
)

type Mountcli struct {
	// The name of the binary we'll be running and parsing. Should almost always
	// be "mount"
	binName string

	// the following vars exist primarily for mocking ability, and ensuring
	// an enclosed environment within the struct.

	// A func to run the given binary and return the output as a string
	binRunner func(string) (string, error)
}

// NewMountcli creates a new Mountcli instance.
func NewMountcli() *Mountcli {
	return &Mountcli{
		binName:   "mount",
		binRunner: binRunner,
	}
}

// GetAllMountedPaths returns all osxfuse mounted paths.
func (m *Mountcli) GetAllMountedPaths() ([]string, error) {
	mounts, err := m.parse()
	if err != nil {
		return nil, err
	}

	paths := []string{}
	for _, m := range mounts {
		paths = append(paths, m.path)
	}

	return paths, nil
}

// FindMountedPathByName returns the mounted paths for the given name.
func (m *Mountcli) FindMountedPathByName(name string) (string, error) {
	mounts, err := m.parse()
	if err != nil {
		return "", err
	}

	for _, m := range mounts {
		if m.name == name {
			return m.path, nil
		}
	}

	return "", ErrNoMountName
}

// FindMountedPathByName returns the mounted name for the given path.
func (m *Mountcli) FindMountNameByPath(path string) (string, error) {
	mounts, err := m.parse()
	if err != nil {
		return "", err
	}

	for _, m := range mounts {
		if m.path == path {
			return m.name, nil
		}
	}

	return "", ErrNoMountPath
}

// GetRelativeMountPath returns the path that's relative to mount path based on
// specified local path. If the specified path and mount are equal, it returns
// an empty string, else it returns the remaining paths.
//
// Ex: if mount path is "/a/b" and local path is "/a/b/c/d", it returns "c/d".
//
// It returns ErrNotInMount if specified local path is not inside or equal to
// mount.
func (m *Mountcli) FindRelativeMountPath(path string) (string, error) {
	mounts, err := m.parse()
	if err != nil {
		return "", err
	}

	splitLocal := strings.Split(path, folderSeparator)
	for _, m := range mounts {
		splitMount := strings.Split(m.path, folderSeparator)

		// if local path is smaller in length than mount, it can't be in it
		if len(splitLocal) < len(splitMount) {
			continue
		}

		// if local path and mount are same size or greater, compare the entries
		for i, localFolder := range splitLocal[:len(splitMount)] {
			if localFolder != splitMount[i] {
				break
			}
		}

		// whatever entries remaining in local path is the relative path
		return filepath.Join(splitLocal[len(splitMount):]...), nil
	}

	return "", ErrNotInMount
}

// IsPathInMountedPath returns if given path is equal to mount or inside a
// mount.
func (m *Mountcli) IsPathInMountedPath(path string) (bool, error) {
	mounts, err := m.parse()
	if err != nil {
		return false, err
	}

	for _, m := range mounts {
		if strings.HasPrefix(path, m.path) {
			return true, nil
		}
	}

	return false, nil
}

func (m *Mountcli) parse() ([]*resp, error) {
	out, err := m.binRunner(m.binName)
	if err != nil {
		return nil, err
	}

	resps := []*resp{}
	lines := strings.Split(out, "\n")
	for _, line := range lines {
		if line == "" {
			continue
		}

		resp := &resp{}

		nMatches := nameMatch.FindStringSubmatch(line)
		if len(nMatches) > 0 {
			resp.name = nMatches[1]
		}
		pMatches := pathMatch.FindStringSubmatch(line)
		if len(pMatches) > 0 {
			resp.path = pMatches[1]
		}

		resps = append(resps, resp)
	}

	return resps, nil
}

///// helpers

type resp struct {
	name string
	path string
}

func binRunner(bin string) (string, error) {
	cmd := exec.Command(bin, "-t", defaultFuseTag)

	out, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}

	return string(out), nil
}
