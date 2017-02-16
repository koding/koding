// mountcli is a package for interacting with the local "mount" command.
//
// See mount_<os>.go for examples.
package mountcli

import (
	"errors"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

var (
	// ErrNotInMount happens when path is not inside/at root level of mount.
	ErrNotInMount = errors.New("Path not run in mount.")

	// ErrNoMountName happens when no mount with given name.
	ErrNoMountName = errors.New("No mount found with given name.")

	// ErrNoMountName happens when no mount there's mount on given path.
	ErrNoMountPath = errors.New("No mount found with given path.")

	// folderSeparator is the os specific separator for dividing folders.
	folderSeparator = string(filepath.Separator)
)

type Mountcli struct {
	// binName is the name of the command that returns results of mounts on the
	// filesystem. It should take -t option that filters specific types of mounts.
	binName string

	// matcher matches name and path from results returned in mount command.
	matcher *regexp.Regexp

	// filterTag is used to filter just specific mounts in mount command.
	filterTag string

	// binRunner is func to run the given binary and return the output as a
	// string. This is used for mocking ability.
	binRunner func(string, string) (string, error)
}

// NewMountcli creates a new Mountcli instance.
func NewMountcli() *Mountcli {
	return &Mountcli{
		binName:   "mount",
		binRunner: binRunner,
		matcher:   FuseMatcher,
		filterTag: FuseTag,
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
// It also works with nested mounted paths.
func (m *Mountcli) FindMountNameByPath(path string) (string, error) {
	path = filepath.Clean(path)

	if relativePath, err := m.FindRelativeMountPath(path); err == nil {
		path = strings.TrimSuffix(path, relativePath)
		path = filepath.Clean(path)
	}

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

// FindRelativeMountPath returns the path that's relative to mount path based on
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
	out, err := m.binRunner(m.binName, m.filterTag)
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

		matches := m.matcher.FindStringSubmatch(line)
		if len(matches) >= 2 {
			resp.name = matches[1]
		}
		if len(matches) >= 3 {
			resp.path = matches[2]
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

func binRunner(bin, defaultFuseTag string) (string, error) {
	cmd := exec.Command(bin, "-t", defaultFuseTag)

	out, err := cmd.CombinedOutput()
	if err != nil {
		return "", err
	}

	return string(out), nil
}
