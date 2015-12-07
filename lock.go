package main

import (
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"os"
	"os/user"
	"path/filepath"
	"strings"
)

var (
	// folderSeparator is the os specific seperator for dividing folders.
	folderSeparator = string(filepath.Separator)

	// lockExtension is the extension of lock files used to identify that file
	// is a lock file.
	lockExtension = ".lock"

	// lockFolderName is the name of the folder where the locks are stored.
	// Klient uses .config/koding folder to store internal files so we store
	// the lock files there as well.
	lockFolderName = filepath.Join(".config", "koding")
)

// Lock locks a folder by creating a .lock file corresponding to that folder.
// This lock file is to be used by external tools to understand a particular
// folder is a kd mounted folder.
//
// Lock files are stored in lockFolderName in base64 so it can be stored flat.
// The file contains the string name of the machine that's mounted in the path.
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

// GetMountedPathsFromLocks returns list of mounted paths based on lock files.
// It returns fully qualified local paths regardless of how lock stores the data
// internally.
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
			name := strings.TrimSuffix(filepath.Base(fi.Name()), lockExtension)
			p, err := base64.StdEncoding.DecodeString(name)
			if err != nil {
				continue
			}

			paths = append(paths, string(p))
		}
	}

	return paths, nil
}

// GetMachineMountedForPath returns name of the machine that's mounted in the
// current directory. Machine name is obtained by the getting the lock file
// of the folder and reading its contents. Note, this works with nested paths
// inside a mount.
//
// It returns ErrNotInMount if specified local path is not inside or equal to
// mount.
func GetMachineMountedForPath(localPath string) (string, error) {
	relativePath, err := GetRelativeMountPath(localPath)
	if err != nil {
		return "", err
	}

	// remove relative path to get the root path of the mount
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
// specified local path. If the specified path and mount are equal, it returns
// an empty string, else it returns the remaining paths.
//
// Ex: if mount path is "/a/b" and local path is "/a/b/c/d", it returns "c/d".
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

		// whatever entries remaining in local path is the relative path
		return filepath.Join(splitLocal[len(splitMount):]...), nil
	}

	return "", ErrNotInMount
}

// IsPathInMountedPath returns true if specified local path is equal to mount
// or inside a mount.
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
	// base64 path, so we can store it in flat in config directory
	path64 := base64.StdEncoding.EncodeToString([]byte(filepath.Clean(path)))

	// prefix config folder and suffix extension
	lockFile := filepath.Join(configFolder, path64+lockExtension)

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
