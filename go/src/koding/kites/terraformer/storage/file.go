package storage

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path"

	"github.com/koding/logging"
)

var _ Interface = (*File)(nil)

// File provides file based storage
type File struct {
	basePath string
	log      logging.Logger
}

// NewFile creates a new folder storage
func NewFile(basePath string, log logging.Logger) (*File, error) {
	f := &File{
		log: log,
	}
	// if base path is empty create a temp one
	if basePath == "" {
		// calling TempDir simultaneously will not choose the same directory.
		var err error
		basePath, err = ioutil.TempDir("", "storage")
		if err != nil {
			return nil, f.errorf(err, "NewFile: tmpdir failed")
		}
	}

	if err := os.MkdirAll(basePath, os.ModePerm); err != nil {
		return nil, f.errorf(err, "NewFile: mkdir %q failed", basePath)
	}

	f.basePath = basePath

	return f, nil
}

// BasePath returns the base path for the storage
func (f *File) BasePath() (string, error) {
	return f.basePath, nil
}

// Write writes to a file with given path
func (f *File) Write(filePath string, file io.Reader) (err error) {
	f.log.Debug("writing %q", filePath)

	dirPath, err := f.fullPath(path.Dir(filePath))
	if err != nil {
		return f.errorf(err, "Write: fullPath of %q failed", path.Dir(filePath))
	}

	if err := os.MkdirAll(dirPath, os.ModePerm); err != nil {
		return f.errorf(err, "Write: mkdir %q failed", dirPath)
	}

	fullPath, err := f.fullPath(filePath)
	if err != nil {
		return f.errorf(err, "Write: fullPath of %q failed", filePath)
	}

	tf, err := os.Create(fullPath)
	if err != nil {
		return f.errorf(err, "Write: creating %q failed", fullPath)
	}

	_, err = io.Copy(tf, file)

	// Sync commits the current contents of the file to disk; even if it
	// fails, try to close the file.
	err = nonil(err, tf.Sync(), tf.Close())
	if err != nil {
		return f.errorf(err, "Write: writing %q failed", fullPath)
	}

	return nil
}

// Remove removes the file from system
func (f File) Remove(filePath string) error {
	f.log.Debug("removing %q", filePath)

	fullPath, err := f.fullPath(filePath)
	if err != nil {
		return f.errorf(err, "Remove: fullPath of %q failed", fullPath)
	}

	if err := os.RemoveAll(fullPath); err != nil && !os.IsNotExist(err) {
		return f.errorf(err, "Remove: removing %q failed", fullPath)
	}

	return nil
}

// Read reads a file.
//
// Caller is responsible for closing the file.
func (f *File) Read(filePath string) (io.Reader, error) {
	f.log.Debug("reading %q", filePath)

	fullPath, err := f.fullPath(filePath)
	if err != nil {
		return nil, f.errorf(err, "Read: fullPath of %q failed", filePath)
	}

	r, err := os.Open(fullPath)
	if err != nil {
		return nil, f.errorf(err, "Read: opening %q failed", fullPath)
	}

	return r, nil
}

// Clone clones underlying files to the target storage
func (f *File) Clone(filePath string, target Interface) error {
	f.log.Debug("cloning %q", filePath)

	fullPath, err := f.fullPath(filePath)
	if err != nil {
		return err
	}

	fileInfos, err := ioutil.ReadDir(fullPath)
	if os.IsNotExist(err) {
		return nil // nothing to copy, return early
	}
	if err != nil {
		return f.errorf(err, "Clone: read %q dir failed", fullPath)
	}

	// TODO(rjeczalik): glob directories and copy files recursively?
	// S3 makes deep copy, copies eveything recursively.
	for _, fileInfo := range fileInfos {
		// Ignore directory, otherwise calling Read on dir is going to fail.
		if fileInfo.IsDir() {
			continue
		}

		fnPath := path.Join(filePath, fileInfo.Name())

		file, err := f.Read(fnPath)
		if err != nil {
			return f.errorf(err, "Clone: reading %q failed", fnPath)
		}

		fpath := path.Join(filePath, fileInfo.Name())
		err = target.Write(fpath, file)

		// If the reader implements io.Closer interface, close the resource.
		f.ensureClosed(file, fpath)

		if err != nil {
			return f.errorf(err, "Clone: writing %q failed", fpath)
		}
	}

	return nil
}

func (f *File) fullPath(filePath string) (string, error) {
	dir, err := f.BasePath()
	if err != nil {
		return "", err
	}

	return path.Join(dir, filePath), nil
}

func (f *File) ensureClosed(r io.Reader, path string) {
	if c, ok := r.(io.Closer); ok {
		if err := c.Close(); err != nil {
			f.log.Warning("failed closing resource path=%q: %s", path, err)
		}
	}
}

func (f *File) errorf(err error, format string, args ...interface{}) error {
	f.log.Error("%s: %s", fmt.Sprintf(format, args...), err)
	return err
}
