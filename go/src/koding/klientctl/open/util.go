package open

import (
	"os"
	"path/filepath"
)

// Prepare a slice of paths to be absolute and/or in a format
// that is friendly to the Koding IDE.
//
// Returns the same list as in, for an easy API.
func PreparePaths(paths []string) ([]string, error) {
	for i, path := range paths {
		path, err := filepath.Abs(path)
		if err != nil {
			return nil, err
		}
		paths[i] = path
	}
	return paths, nil
}

// Like MkdirAll, Mkfiles creates any files as needed.
func Mkfiles(paths []string, perm os.FileMode) error {
	for _, path := range paths {
		_, err := os.Stat(path)
		if os.IsNotExist(err) {
			if err := os.MkdirAll(filepath.Dir(path), perm); err != nil {
				return err
			}

			// The file doesn't exist, create it.
			f, err := os.Create(path)
			if err != nil {
				return err
			}
			f.Chmod(perm)
			f.Close()
		} else if err != nil {
			// If we don't know what to do with the error, it might be
			// permissions/etc. Return it.
			return err
		}
	}
	return nil
}

// Split a slice of paths into files and dirs.
func FileOrDir(paths []string) (files, dirs []string, err error) {
	var fi os.FileInfo
	for _, path := range paths {
		fi, err = os.Stat(path)
		if err != nil {
			return nil, nil, err
		}
		if fi.IsDir() {
			dirs = append(dirs, path)
		} else {
			files = append(files, path)
		}
	}
	return
}
