package lock

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"strings"
)

const lockFolderName = ".fuseklient"

// Lock locks a folder by creating a .lock file corresponding to that folder.
// This lock file is to be used by external tools to understand a particular
// folder is a Fuse mounted folder.
//
// Lock files are stored in `~/.fuseklient`; slashes in path are replaces
// with _ in file name; ie if `/path/to/mount` folder is mounted then
// `~/.fuseklient/path_to_mount.lock` will be created.
func Lock(path string) error {
	lockFile, err := getLockFileName(path)
	if err != nil {
		return err
	}

	if _, err := os.Stat(lockFile); err == nil {
		return fmt.Errorf("Lock file: '%s' exists. Please remove to continue.", lockFile)
	}

	fmt.Printf("Creating lock file: '%s'\n\n", lockFile)

	_, err = os.Create(lockFile)
	return err
}

// Unlock removes ~/.fuseklient/path_to_mount.lock file.
func Unlock(path string) error {
	lockFile, err := getLockFileName(path)
	if err != nil {
		return err
	}

	fmt.Printf("\nDeleting lock file: '%s'\n", lockFile)

	return os.Remove(lockFile)
}

// getLockFileName returns name of lock file for mounted folder. It uses
// absolute path in lock file name even when relative path is given.
func getLockFileName(path string) (string, error) {
	configFolder, err := getOrCreateConfigFolder()
	if err != nil {
		return "", err
	}

	mountName := strings.Replace(path, "/", "_", -1)
	lockFile := filepath.Join(configFolder, mountName+".lock")

	return lockFile, nil
}

// getOrCreateConfigFolder creates `~/.fuseklient` folder unless it exists.
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
