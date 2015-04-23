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
	Clone(string, Storage) error
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

func (s S3Storage) Clone(path string, target Storage) error {
	filePath := path + "/"
	// Limits the response to keys that begin with the specified prefix. You can
	// use prefixes to separate a bucket into different groupings of keys. (You
	// can think of using prefix to make groups in the same way you'd use a
	// folder in a file system.)
	prefix := filePath

	// If you don't specify the prefix parameter, then the substring starts at
	// the beginning of the key
	delim := ""

	// Specifies the key to start with when listing objects in a bucket. Amazon
	// S3 returns object keys in alphabetical order, starting with key after the
	// marker in order.
	marker := ""

	// Sets the maximum number of keys returned in the response body. You can
	// add this to your request if you want to retrieve fewer than the default
	// 1000 keys.
	max := 0

	// read all elements in a bucket, we are gonna have more than 1000 items in
	// that bucket/folder
	result, err := s.bucket.List(prefix, delim, marker, max)
	if err != nil {
		return err
	}

	// write them all to target
	for _, res := range result.Contents {
		newPath := res.Key
		r, err := s.Read(newPath)
		if err != nil {
			return err
		}

		if err := target.Write(newPath, r); err != nil {
			return err
		}
	}

	return nil
}

type FileStorage struct {
	basePath string
}

func NewFileStorage(basePath string) FileStorage {
	return FileStorage{
		basePath: basePath,
	}
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
func (f FileStorage) Clone(filePath string, target Storage) error {
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

func (f FileStorage) fullPath(filePath string) (string, error) {
	dir, err := f.BasePath()
	if err != nil {
		return "", err
	}

	return path.Join(dir, filePath), nil
}
