package fuseklient

import (
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"os/user"
	"path/filepath"
	"strings"
)

var (
	// lockReplaceSep is the seperator for dividing folders in the lock file
	// using flat structure. note this needs to be unique enough so it doesn't
	// conflict with common strings in file names.
	lockReplaceSep = "_-_"

	// folderSeparator is the os specific seperator for diving folders.
	folderSeparator = string(filepath.Separator)
	lockExtension   = ".lock"
	lockFolderName  = filepath.Join(".config", "koding")

	ErrNotInMount = errors.New("path not in mount")
)

// Lock locks a folder by creating a .lock file corresponding to that folder.
// This lock file is to be used by external tools to understand a particular
// folder is a Fuse mounted folder.
//
// Lock files are stored in lockFolderName; slashes in path are replaced with
// with lockReplaceSep in file name so it can be stored flat.
func Lock(path, machine string) error {
	lockFile, err := getLockFileName(path)
	if err != nil {
		return err
	}

	if _, err := os.Stat(lockFile); err == nil {
		return fmt.Errorf("Lock file: '%s' exists. Please remove to continue.", lockFile)
	}

	return ioutil.WriteFile(lockFile, []byte(machine), 0644)
}

// Unlock removes the lock file. If lock file doesn't exist, it returns nil. We
// don't care about the operation status just that the lock file doesn't exist.
func Unlock(path string) error {
	lockFile, err := getLockFileName(path)
	if err != nil {
		return err
	}

	if _, err := os.Stat(lockFile); os.IsNotExist(err) {
		return nil
	}

	return os.Remove(lockFile)
}

// GetMountedPathsFromLocks returns list of mounted paths based on lock files
// stored in config folder. It returns proper filepaths regardless of how lock
// stores it internally.
func GetMountedPathsFromLocks() ([]string, error) {
	configFolder, err := getOrCreateConfigFolder()
	if err != nil {
		return nil, err
	}

	filesInfo, err := ioutil.ReadDir(configFolder)
	if err != nil {
		return nil, err
	}

	var paths []string
	for _, fi := range filesInfo {
		if filepath.Ext(fi.Name()) == lockExtension {
			p := fi.Name()
			p = strings.Replace(p, lockReplaceSep, folderSeparator, -1)
			p = strings.TrimSuffix(p, lockExtension)

			paths = append(paths, p)
		}
	}

	return paths, nil
}

// GetMachineMountedForPath returns name of the machine that's mounted in the
// current directory.
func GetMachineMountedForPath(localPath string) (string, error) {
	relativePath, err := GetRelativeMountPath(localPath)
	if err != nil {
		return "", err
	}

	rootMountPath := strings.TrimSuffix(localPath, relativePath)
	lockFile, err := getLockFileName(rootMountPath)
	if err != nil {
		return "", err
	}

	if _, err := os.Stat(lockFile); os.IsNotExist(err) {
		return "", ErrNotInMount
	}

	contents, err := ioutil.ReadFile(lockFile)
	if err != nil {
		return "", err
	}

	return string(contents), nil
}

// GetRelativeMountPath returns the path that's relative to mount path based on
// specified local path. If the specified path and mount is the same, it returns
// and empty string.
//
// Ex: if mount path is "/a/b" and local path is "/a/b/c", it returns "c".
//
// It returns ErrNotInMount if specified local path is not inside or equal to
// mount.
func GetRelativeMountPath(localPath string) (string, error) {
	mPaths, err := GetMountedPathsFromLocks()
	if err != nil {
		return "", err
	}

	splitLocal := strings.Split(localPath, folderSeparator)
	for _, m := range mPaths {
		splitMount := strings.Split(m, folderSeparator)

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

		// whatever entries remaining in local path is the relative pat
		return filepath.Join(splitLocal[len(splitMount):]...), nil
	}

	return "", ErrNotInMount
}

// IsPathInMountedPath returns bool to indicate if specified local path is equal
// to mont or inside a mount.
func IsPathInMountedPath(localPath string) (bool, error) {
	mPaths, err := GetMountedPathsFromLocks()
	if err != nil {
		return false, err
	}

	for _, m := range mPaths {
		if strings.HasPrefix(localPath, m) {
			return true, nil
		}
	}

	return false, nil
}

// getLockFileName returns name of lock file for mounted folder. It uses
// absolute path in lock file name even when relative path is given.
func getLockFileName(path string) (string, error) {
	configFolder, err := getOrCreateConfigFolder()
	if err != nil {
		return "", err
	}

	// clean trailing seperators at end of path
	path = filepath.Clean(path)

	mountName := strings.Replace(path, folderSeparator, lockReplaceSep, -1)
	lockFile := filepath.Join(configFolder, mountName+lockExtension)

	return lockFile, nil
}

// getOrCreateConfigFolder creates config folder unless it exists.
func getOrCreateConfigFolder() (string, error) {
	usr, err := user.Current()
	if err != nil {
		return "", err
	}

	folderName := filepath.Join(usr.HomeDir, lockFolderName)
	if err := os.MkdirAll(folderName, 0755); err != nil {
		return "", nil
	}

	return folderName, nil
}
