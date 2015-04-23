package kodingcontext

import (
	"io"
	"io/ioutil"
	"os"

	"github.com/mitchellh/goamz/s3"
)

type Storage interface {
	Write(string, io.Reader) error
	Read(string) (io.Reader, error)
	Remove(string) error
	BasePath() (string, error)
	Clean(string) error
}

var _ Storage = S3Storage{}
var _ Storage = FileStorage{}

type S3Storage struct {
	// Bucket holds the plans of terraform
	bucket *s3.Bucket
}

func NewS3Storage() *S3Storage {
	return &S3Storage{}
}

func (s S3Storage) BasePath() (string, error) {
	return "", nil
}

func (s S3Storage) Clean(path string) error {
	return nil
}

func (s S3Storage) Write(path string, file io.Reader) error {
	// TODO(cihangir): we can use bucket.PutReader here
	content, err := ioutil.ReadAll(file)
	if err != nil {
		return err
	}

	err = s.bucket.Put(path, content, "application/json", s3.Private)
	if err != nil {
		return err
	}

	return nil
}

func (s S3Storage) Remove(path string) error {
	if err := s.bucket.Del(path); err != nil {
		return err
	}

	return nil
}

func (s S3Storage) Read(path string) (io.Reader, error) {
	if r, err := s.bucket.GetReader(path); err != nil {
		return nil, err
	} else {
		return r, nil
	}
}

type FileStorage struct {
	basePath string
}

func (f FileStorage) BasePath() (string, error) {
	if f.basePath != "" {
		return f.basePath, nil
	}

	// create dir
	// calling TempDir simultaneously will not choose the same directory.
	dir, err := ioutil.TempDir("", "storage")
	if err != nil {
		return "", err
	}

	f.basePath = dir

	return f.basePath, nil
}

func (f FileStorage) Clean(path string) error {
	return os.RemoveAll(path)
}

func (f FileStorage) Write(path string, file io.Reader) (err error) {
	tf, err := os.Create(path)
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

func (f FileStorage) Remove(path string) error {
	if err := os.RemoveAll(path); err != nil {
		return err
	}

	return nil
}

func (f FileStorage) Read(path string) (io.Reader, error) {
	if r, err := os.Open(path); err != nil {
		return nil, err
	} else {
		return r, nil
	}
}
