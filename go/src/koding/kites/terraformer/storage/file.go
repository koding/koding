package storage

import (
	"io"
	"io/ioutil"
	"os"
	"path"
	"strings"
)

var _ Interface = File{}

// File provides file based storage
type File struct {
	basePath string
}

// NewFile creates a new folder storage
func NewFile(basePath string) (File, error) {
	// if base path is empty create a temp one
	if basePath == "" {
		// calling TempDir simultaneously will not choose the same directory.
		var err error
		basePath, err = ioutil.TempDir("", "storage")
		if err != nil {
			return File{}, err
		}
	}

	if err := os.MkdirAll(basePath, os.ModePerm); err != nil {
		return File{}, err
	}

	return File{
		basePath: basePath,
	}, nil
}

// BasePath returns the base path for the storage
func (f File) BasePath() (string, error) {
	return f.basePath, nil
}

// Write writes to a file with given path
func (f File) Write(filePath string, file io.Reader) (err error) {
	contents := strings.Split(filePath, string(os.PathSeparator))

	dirPath, err := f.fullPath(strings.Join(contents[:len(contents)-1], string(os.PathSeparator)))
	if err != nil {
		return err
	}

	if err := os.MkdirAll(dirPath, os.ModePerm); err != nil {
		return err
	}

	fullPath, err := f.fullPath(filePath)
	if err != nil {
		return err
	}

	tf, err := os.Create(fullPath)
	if err != nil {
		return err
	}

	defer func() {
		// Sync commits the current contents of the file to disk
		if err = tf.Sync(); err != nil {
			return
		}

		if err = tf.Close(); err != nil {
			return
		}
	}()

	_, err = io.Copy(tf, file)
	return err
}

// Remove removes the file from system
func (f File) Remove(filePath string) error {
	fullPath, err := f.fullPath(filePath)
	if err != nil {
		return err
	}

	if err := os.RemoveAll(fullPath); err != nil {
		return err
	}

	return nil
}

// Read reads a file
func (f File) Read(filePath string) (io.Reader, error) {
	fullPath, err := f.fullPath(filePath)
	if err != nil {
		return nil, err
	}

	r, err := os.Open(fullPath)
	if err != nil {
		return nil, err
	}

	return r, nil
}

// Clone clones underlying files to the target storage
func (f File) Clone(filePath string, target Interface) error {
	fullPath, err := f.fullPath(filePath)
	if err != nil {
		return err
	}

	fileInfos, err := ioutil.ReadDir(fullPath)
	if err != nil {
		return err
	}

	for _, fileInfo := range fileInfos {
		fnPath := path.Join(filePath, fileInfo.Name())

		file, err := f.Read(fnPath)
		if err != nil {
			return err
		}

		fpath := path.Join(filePath, fileInfo.Name())
		if err := target.Write(fpath, file); err != nil {
			return err
		}
	}

	return nil
}

func (f File) fullPath(filePath string) (string, error) {
	dir, err := f.BasePath()
	if err != nil {
		return "", err
	}

	return path.Join(dir, filePath), nil
}
