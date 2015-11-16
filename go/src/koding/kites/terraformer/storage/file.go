package storage

import (
	"io"
	"io/ioutil"
	"os"
	"path"
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
	dirPath, err := f.fullPath(path.Dir(filePath))
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
		// Sync commits the current contents of the file to disk; even if it
		// fails, try to close the file.
		err = nonil(err, tf.Sync(), tf.Close())
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
