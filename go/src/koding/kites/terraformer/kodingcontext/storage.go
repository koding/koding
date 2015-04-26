package kodingcontext

import (
	"io"
	"io/ioutil"
	"os"
	"path"
	"strings"

	"github.com/mitchellh/goamz/aws"
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

func NewS3Storage(key, secret, bucketName string) (S3Storage, error) {
	// init s3 auth
	awsAuth, err := aws.GetAuth(key, secret)
	if err != nil {
		return S3Storage{}, err
	}

	// we are only using us east
	awsS3Bucket := s3.New(awsAuth, aws.USEast).Bucket(bucketName)

	if err := awsS3Bucket.PutBucket(s3.Private); err != nil {
		return S3Storage{}, err
	}

	return S3Storage{
		bucket: awsS3Bucket,
	}, nil
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

		// if bucket is created but doesnt have
		if newPath == filePath {
			continue
		}

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

func NewFileStorage(basePath string) (FileStorage, error) {
	if err := os.MkdirAll(basePath, os.ModePerm); err != nil {
		return FileStorage{}, err
	}

	return FileStorage{
		basePath: basePath,
	}, nil
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

func (f FileStorage) Clean(filePath string) error {
	fullPath, err := f.fullPath(filePath)
	if err != nil {
		return err
	}

	return os.RemoveAll(fullPath)
}

func (f FileStorage) Write(filePath string, file io.Reader) (err error) {
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

func (f FileStorage) Remove(filePath string) error {
	fullPath, err := f.fullPath(filePath)
	if err != nil {
		return err
	}

	if err := os.RemoveAll(fullPath); err != nil {
		return err
	}

	return nil
}

func (f FileStorage) Read(filePath string) (io.Reader, error) {
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
