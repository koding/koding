package mounttest

import (
	"io/ioutil"
	"os"

	"koding/klient/machine/mount"
)

// MountDirs creates a set of temporary directories that are useful for tests.
//
//  - wd: mount working directory where cache and indexes are stored.
//  - m.Path: directory into which remote data are mounted.
//  - m.RemotePath: remote directory with one sample temp file.
//
// One must run clean function in order to release resources.
func MountDirs() (wd string, m mount.Mount, clean func(), err error) {
	// Create path to be mounted.
	remotePath, rpClean, err := TempDir()
	if err != nil {
		return "", m, nil, err
	}
	defer func() {
		if err != nil {
			rpClean()
		}
	}()

	// Put a sample file into remote directory.
	if _, err := TempFile(remotePath); err != nil {
		return "", m, nil, err
	}

	// Create destination path.
	path, lpClean, err := TempDir()
	if err != nil {
		return "", m, nil, err
	}
	defer func() {
		if err != nil {
			lpClean()
		}
	}()

	// Create working directory.
	wd, wdClean, err := TempDir()
	if err != nil {
		return "", m, nil, err
	}
	defer func() {
		if err != nil {
			wdClean()
		}
	}()

	clean = func() {
		wdClean()
		lpClean()
		rpClean()
	}

	m = mount.Mount{
		Path:       path,
		RemotePath: remotePath,
	}

	return wd, m, clean, nil
}

// TempDir creates a temporary directory with `mount` prefix.
func TempDir() (root string, clean func(), err error) {
	root, err = ioutil.TempDir("", "mount")
	if err != nil {
		return "", nil, err
	}

	return root, func() { os.RemoveAll(root) }, nil
}

// TempFile creates a temporary file with `mount` prefix and `simple` content.
func TempFile(root string) (string, error) {
	f, err := ioutil.TempFile(root, "mount")
	if err != nil {
		return "", nil
	}
	defer f.Close()

	if _, err := f.WriteString("sample"); err != nil {
		return "", err
	}

	return f.Name(), nil
}
